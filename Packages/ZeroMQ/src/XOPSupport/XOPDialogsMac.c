/*	This file contains the Macintosh implemention of cross-platform utility dialogs.

	If you are porting an XOP that creates dialogs to XOP Toolkit 7 from
	an earlier version, see the section on dialogs in Appendix A of the
	XOP Toolkit 7 manual.
*/

#import <Cocoa/Cocoa.h>
#include <CoreFoundation/CFURL.h>
#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	XOPEmergencyAlert(message)
	
	This routine used by the XOP Toolkit for dire emergencies only.
	You should not need it. Use XOPOKAlert instead.
	
	Thread Safety: XOPEmergencyAlert is not thread-safe.
*/
void
XOPEmergencyAlert(const char* message)
{
	NSString* nsMessage = [ NSString stringWithUTF8String:message ];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:@"Emergency"];		// Title
	[alert setInformativeText:nsMessage];		// Message
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
}

/*	XOPOKAlert(title, message)
	
	Thread Safety: XOPOKAlert is not thread-safe.
*/
void
XOPOKAlert(const char* title, const char* message)
{
	if (!CheckRunningInMainThread("XOPOKAlert"))
		return;

	NSString* nsTitle = [ NSString stringWithUTF8String:title ];
	NSString* nsMessage = [ NSString stringWithUTF8String:message ];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:nsTitle];				// Title
	[alert setInformativeText:nsMessage];		// Message
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
}

/*	XOPOKCancelAlert(title, message)

	Returns 1 for OK, -1 for cancel.
	
	Thread Safety: XOPOKCancelAlert is not thread-safe.
*/
int
XOPOKCancelAlert(const char* title, const char* message)
{
	if (!CheckRunningInMainThread("XOPOKCancelAlert"))
		return -1;

	NSString* nsTitle = [ NSString stringWithUTF8String:title ];
	NSString* nsMessage = [ NSString stringWithUTF8String:message ];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:nsTitle];				// Title
	[alert setInformativeText:nsMessage];		// Message
	[alert addButtonWithTitle:@"Cancel"];		// Right button
	[alert addButtonWithTitle:@"OK"];			// Left button
	NSInteger buttonCode = [alert runModal];

	int result;
	switch(buttonCode) {
		case NSAlertFirstButtonReturn:			// Right button
			result = -1;						// Cancel
			break;
		case NSAlertSecondButtonReturn:			// Left button
			result = 1;							// OK
			break;
		default:
			result = -1;
			break;
	}
	return result;
}

/*	XOPYesNoAlert(title, message)

	Returns 1 for yes, 2 for no.
	
	Thread Safety: XOPYesNoAlert is not thread-safe.
*/
int
XOPYesNoAlert(const char* title, const char* message)
{
	if (!CheckRunningInMainThread("XOPYesNoAlert"))
		return 2;

	NSString* nsTitle = [ NSString stringWithUTF8String:title ];
	NSString* nsMessage = [ NSString stringWithUTF8String:message ];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:nsTitle];				// Title
	[alert setInformativeText:nsMessage];		// Message
	[alert addButtonWithTitle:@"No"];			// Right button
	[alert addButtonWithTitle:@"Yes"];			// Left button
	NSInteger buttonCode = [alert runModal];

	int result;
	switch(buttonCode) {
		case NSAlertFirstButtonReturn:			// Right button
			result = 2;							// No
			break;
		case NSAlertSecondButtonReturn:			// Left button
			result = 1;							// Yes
			break;
		default:
			result = -1;
			break;
	}
	return result;
}

/*	XOPYesNoCancelAlert(title, message)

	Returns 1 for yes, 2 for no, -1 for cancel.
	
	Thread Safety: XOPYesNoCancelAlert is not thread-safe.
*/
int
XOPYesNoCancelAlert(const char* title, const char* message)
{
	if (!CheckRunningInMainThread("XOPYesNoCancelAlert"))
		return -1;

	NSString* nsTitle = [ NSString stringWithUTF8String:title ];
	NSString* nsMessage = [ NSString stringWithUTF8String:message ];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:nsTitle];				// Title
	[alert setInformativeText:nsMessage];		// Message
	[alert addButtonWithTitle:@"Cancel"];		// Right button
	[alert addButtonWithTitle:@"No"];			// Center button
	[alert addButtonWithTitle:@"Yes"];			// Left button
	NSInteger buttonCode = [alert runModal];

	int result;
	switch(buttonCode) {
		case NSAlertFirstButtonReturn:			// Right button
			result = -1;						// Cancel
			break;
		case NSAlertSecondButtonReturn:			// Center button
			result = 2;							// No
			break;
		case NSAlertThirdButtonReturn:			// Left button
			result = 1;							// Yes
			break;
		default:
			result = -1;
			break;
	}
	return result;
}

static const int kMaxExtensionBytes = 31;

/*	GetNextExtension(pp, extension)

	This routine parses a file filter string as defined for XOPOpenFileDialog on Macintosh.
	It returns the next extension in the file filter string or "" via extension.
	The function result is true if there was a next extension or false otherwise.
	
	The filter string as defined for XOPOpenFileDialog on Macintosh looks like this:
		"Text Files:TEXT,IGTX:.txt,.itx;All Files:****:;"
	This format was chosen in the dark ages, long before OS X. TEXT and IGTX are Mac OS 9
	file type codes. Apple abandoned file types in Mac OS X and this routine ignores them.
	It returns only extensions such as ".txt" and ".itx". It does not handle "****" - it is
	up to the calling routine to detect that and handle it appropriately.
	
	The trailing semicolon is required.
	
	The extensions returned exclude the leading dot.
	
	It also sets *pp as needed for the next time it is called.
*/
static bool GetNextExtension(const char** pp, char extension[kMaxExtensionBytes+1]);
static bool
GetNextExtension(const char** pp, char extension[kMaxExtensionBytes+1])	// Returns true if there was another extension available
{
	const char* pIn = *pp;
	char* pOut = extension;
	bool inExtension = false;
	int numBytesWritten = 0;
	bool gotExtension = false;
	
	MemClear(extension, kMaxExtensionBytes+1);
	
	while(1) {
		int ch = *pIn++;
		if (ch == 0)
			break;
		if (ch == '.') {
			if (inExtension) {
				// Programmer error - can't use dot inside an extension
				gotExtension = false;					// This will terminate the loop in the calling routine
				break;
			}
			else {
				inExtension = true;
				continue;
			}
		}
		if (ch == ',') {
			// End of one extension of a group
			inExtension = false;
			gotExtension = numBytesWritten > 0;
			break;
		}
		if (ch == ';') {
			// End of a group of extensions
			inExtension = false;
			gotExtension = numBytesWritten > 0;
			break;
		}
		if (numBytesWritten >= kMaxExtensionBytes) {
			// Programmer error - extension too long
			gotExtension = false;						// This will terminate the loop in the calling routine
			break;
		}
		if (inExtension) {
			*pOut++ = ch;
			numBytesWritten += 1;
		}
	}
	
	*pp = pIn;
	
	return gotExtension;
}

/*	XOPOpenFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDir, filePath)

	Displays the Open File dialog.
	
	If you are writing new code or updating existing code that requires Igor7 or later,
	use XOPOpenFileDialog2 instead of XOPOpenFileDialog. XOPOpenFileDialog2 provides a cleaner,
	platform-independent interface. Use XOPOpenFileDialog only if you must support Igor6.
	
	XOPOpenFileDialog returns 0 if the user chooses a file or -1 if the user cancels or another
	non-zero number in the event of an error. It returns the full path to the file via filePath.
	filePath is a native path, using colons on Macintosh, backslashes on Windows. In the event
	of a cancel, filePath is unmodified.
	
	prompt sets the dialog window title.
	
	If fileFilterStr is "", then the Open File dialog displays all types of files, both on
	Macintosh and Windows. If fileFilterStr is not "", it identifies the type of files to display.

	On Macintosh, fileFilterStr looks like this:
		"Text Files:TEXT,IGTX:.txt,.itx;All Files:****:;"
	This format was chosen in the dark ages, long before OS X. TEXT and IGTX are Mac OS 9
	file type codes. Apple abandoned file types in Mac OS X and this routine ignores them.
	It recognizes only extensions such as ".txt" and ".itx", introduced by a dot and followed
	by a comma or semicolon, and ignores any other text in the string. Files ending with an
	extension that appears in fileFilterStr are selectable in the dialog. If fileFilterStr
	contains "****", all files are selectable.
	
	On Windows, fileFilterStr is constructed as for the lpstrFilter field of the OPENFILENAME
	structure for the Windows GetOpenFileName routine. For example, to allow the user to select
	text files and Igor Text files, use
		"Text Files (*.txt)\0*.txt\0Igor Text Files (*.itx)\0*.itx\0All Files (*.*)\0*.*\0\0".
	Note that the string ends with two null characters (\0\0). You can specify multiple extensions
	for a single type of file by listing the extensions with a semicolon between them. For example:
		"Excel Files (*.xls,*.xlsx)\0*.xls;*.xlsx\0All Files (*.*)\0*.*\0\0");
	
	fileIndexPtr is ignored on Macintosh in XOP Toolkit 7 because the Cocoa NSOpenPanel
	class, on which XOPOpenFileDialog is now based, does not support a File Type popup menu.
	The rest of this paragraph applies on Windows and on Macintosh with XOP Toolkit 6.
	fileIndexPtr is ignored if it is NULL. If it is not NULL, then *fileIndexPtr is the
	one-based index of the file type filter to be initially selected. In the example given above,
	setting *fileIndexPtr to 2 would select the Igor Text file type on entry to the dialog.
	On exit from the dialog, *fileIndexPtr is set to the index of the file type string that
	the user last selected.
	
	initialDir can be "" or it can point to a full path to a directory. It determines
	the directory that will be initially displayed in the Open File dialog. If it is "",
	the directory will be the last directory that was seen in the Open or Save file dialogs.
	If initialDir points to a valid path to a directory, then this directory will be initially
	displayed in the dialog. On Macintosh, initialDir is a Macintosh HFS path using colons.
	On Windows, it is a Windows path using backslashes.
	
	XOPOpenFileDialog returns via filePath the full path to the file that the user chose.
	filePath is unchanged if the user cancels. On Macintosh, filePath is a Macintosh HFS path
	using colons. On Windows, it is a Windows path using backslashes. filePath must point
	to a buffer of at least MAX_PATH_LEN+1 bytes.
	
	On Windows, the initial value of filePath sets the initial contents of the File Name edit
	control in the Open File dialog. The following values are valid:
		""
		a file name
		a full Mac or Windows path to a file
	
	On Macintosh, the initial value of filePath is not currently used. It should be set
	the same as for Windows because it may be used in the future.
	
	Thread Safety: XOPOpenFileDialog is not thread-safe.
*/
int
XOPOpenFileDialog(
	const char* prompt,
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	char filePath[MAX_PATH_LEN+1])
{
	int err = 0;
	
	NSOpenPanel* panel = [[NSOpenPanel openPanel] retain];

	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	
	NSMutableArray* fileTypes = nil;
	int extensionCount = 0;
	if (strstr(fileFilterStr, "****") == NULL) {			// "All Files:****;" is not in the filter string?
		fileTypes = [NSMutableArray arrayWithCapacity:10];	// Auto-released
		const char* p = fileFilterStr;
		char extension[kMaxExtensionBytes+1];
		while(GetNextExtension(&p, extension)) {
			NSString* extensionStr = [ NSString stringWithUTF8String:extension];		// Auto-released
			[ fileTypes addObject:extensionStr];
		}
		extensionCount = [fileTypes count];
	}
	if (extensionCount > 0)
		[panel setAllowedFileTypes:fileTypes];

	NSString* titleStr = [NSString stringWithUTF8String:prompt];		// Auto-released
	[panel setTitle:titleStr];											// Copies titleStr
	
	if (*initialDir != 0) {
		char posixPath[MAX_PATH_LEN+1];
		int err2 = HFSToPosixPath(initialDir, posixPath, 1);
		if (err2 == 0) {
			NSURL* initialDirURL = [ NSURL fileURLWithFileSystemRepresentation:posixPath isDirectory:NO relativeToURL:nil ];	// Auto-released
			NSError* error;
			if ([initialDirURL checkResourceIsReachableAndReturnError:&error] == YES)
				[panel setDirectoryURL:initialDirURL];
		}
	}
	
	NSInteger result = [panel runModal];
	if (result != NSFileHandlingPanelOKButton) {
		[panel release];
		return -1;										// Cancel
	}

	NSURL* fileURL = [panel URL];						// Auto-released
	CFStringRef ref = CFURLCopyFileSystemPath((CFURLRef)fileURL, kCFURLHFSPathStyle);
	NSString* hfsPathStr = (NSString*)ref;				// We own this
	const char* hfsPath = [ hfsPathStr UTF8String ];
	int len = (int)strlen(hfsPath);
	if (len > MAX_PATH_LEN)
		err = PATH_TOO_LONG;
	else
		strcpy(filePath, hfsPath);
	[hfsPathStr release];

	[panel release];
	
	return err;
}

/*	XOPOpenFileDialog2(flagsIn, prompt, fileFilterStr, fileFilterIndexPtr, initialDir, initialFile, flagsOutPtr, fullPathOut)

	Displays the Open File dialog.
	
	XOPOpenFileDialog2 requires Igor Pro 7.00 or later. With earlier versions,
	it returns an error. If your XOP must run with Igor6, use XOPFileDialog instead.
	
	XOPOpenFileDialog2 returns 0 if the user chooses a file, or -1 if the user cancels,
	or another non-zero number in the event of an error.
	
	It returns the full path to the chosen file via fullPathOut. This is a native path,
	using colons on Macintosh, backslashes on Windows.
	
	In the event of a cancel, fullPathOut is unmodified.
	
	flagsIn is currently unused. Pass 0 for this parameter.
	
	prompt sets the dialog window title.
	
	fileFilterStr controls the filters in the file filter popup menu that appears in
	the Open File dialog. The construction of this string is the same as documented
	in the Igor help for the Open operation /F flag. For example, this populate the
	filter popup menu with three filters:
	
	const char* fileFilters = "Data Files (*.txt,*.dat,*.csv):.txt,.dat,.csv;" \
							  "HTML Files (*.htm,*.html):.htm,.html;" \
							  "All Files:.*;";
	
	fileFilterIndexPtr is ignored if it is NULL. If it is not NULL, then
	*fileFilterIndexPtr is the 1-based index of the file type filter to be initially
	selected. In the example given above, setting *fileFilterIndexPtr to 1 would select
	the "HTML Files" file filter on entry to the dialog. On exit from the dialog,
	*fileFilterIndexPtr is set to the 1-based index of the file filter string that
	the user last selected.
	
	initialDir can be "" or it can point to a full native path to a directory, with
	or without the trailing path separator. It determines the directory that will be
	initially displayed in the Open File dialog. If "", the directory will be the
	last directory that was seen in the Open File or Save File dialogs. initialDir
	is a native path using colons on Macintosh, backslashes on Windows.
	
	initialFile can be "" or it can be the name to which the File Name edit control
	in the Open File dialog is to be initialized. initialFile works on Windows only
	because the Macintosh Open File dialog has no File Name edit control.

	flagsOutPtr is currently unused. Pass NULL for this parameter.
	
	XOPOpenFileDialog2 returns, via fullPathOut, the full path to the file that the
	user chose. If the user cancels, fullPathOut is unchanged. fullPathOut is a
	native path using colons on Macintosh, backslashes on Windows.
 
	Thread Safety: XOPOpenFileDialog2 is not thread-safe.
*/
int
XOPOpenFileDialog2(
	int flagsIn,						// Currently unused - must be 0
	const char* prompt,
	const char* fileFilterStr,
	int* fileFilterIndexPtr,			// Can be NULL
	const char* initialDir,
	const char* initialFile,			// Sets initial contents of File Name edit control on Windows only
	int* flagsOutPtr,					// Currently unused - must be NULL
	char fullPathOut[MAX_PATH_LEN+1])
{
	return (int)CallBack8(XOP_OPEN_FILE_DIALOG_2, XOP_CALLBACK_INT(flagsIn), (void*)prompt, (void*)fileFilterStr, fileFilterIndexPtr, (void*)initialDir, (void*)initialFile, flagsOutPtr, fullPathOut);
}

/*	XOPSaveFileDialog(prompt, fileFilterStr, fileIndexPtr, initialDir, defaultExtension, filePath)

	Displays the Save File dialog.
	
	If you are writing new code or updating existing code that requires Igor7 or later,
	use XOPSaveFileDialog2 instead of XOPSaveFileDialog. XOPSaveFileDialog2 provides a cleaner,
	platform-independent interface. Use XOPSaveFileDialog only if you must support Igor6.
	
	XOPSaveFileDialog returns 0 if the user provides a file name or -1 if the user cancels
	or another non-zero number in the event of an error.
	
	XOPSaveFileDialog returns the full path to the file via filePath. filePath is both an
	input and an output as explained below. In the event of a cancel, filePath is unmodified.
	On Macintosh, filePath is a Macintosh HFS path using colons. On Windows, it is a Windows
	path using backslashes. filePath must point to a buffer of at least MAX_PATH_LEN+1 bytes.
	
	prompt sets the dialog window title.
	
	fileFilterStr specifies the allowed file name extensions.
	
	On Macintosh, fileFilterStr looks like this:
		"Plain Text:TEXT:.txt;Igor Text:.itx;All Files:****:;"
	This format was chosen in the dark ages, long before OS X. TEXT and IGTX are Mac OS 9
	file type codes. Apple abandoned file types in Mac OS X and this routine ignores them.
	It recognizes only extensions such as ".txt" and ".itx", introduced by a dot and followed
	by a comma or semicolon, and ignores any other text in the string. If fileFilterStr
	contains "****", the user can enter any extension. Otherwise the following rules apply.
	The dialog permits the user to use any extension that appears in fileFilterStr or the
	extension specified by defaultExtension. If fileFilterStr is "", the extension defaults
	to that specified by defaultExtension or to ".txt" if defaultExtension is "". If the user
	enters no extension in the Save File dialog name field or enters an extension that is not
	listed in fileFilterStr or defaultExtension, the dialog appends the default extension
	as specified by defaultExtension, or by the first extension that appears in fileFilterStr
	if defaultExtension is "", or ".txt" if fileFilterStr is also "".

	On Windows, fileFilterStr identifies the types of files to display and the types of files
	that can be created. It is constructed as for the lpstrFilter field of the OPENFILENAME
	structure for the Windows GetSaveFileName routine. For example, to allow the user to save
	as a text file or as an Igor Text file, use
		"Plain Text (*.txt)\0*.txt\0Igor Text (*.itx)\0*.itx\0\0"
	Note that the string ends with two null characters (\0\0). If fileFilterStr is "", this
	behaves the same as "Plain Text (*.txt)\0*.txt\0\0".
	
	fileIndexPtr is ignored on Macintosh in XOP Toolkit 7 because the Cocoa NSSavePanel
	class, on which XOPSaveFileDialog is now based, does not support a File Type popup menu.
	The rest of this paragraph applies on Windows and on Macintosh with XOP Toolkit 6.
	fileIndexPtr is ignored if it is NULL. If it is not NULL, then *fileIndexPtr is the
	one-based index of the file type filter to be initially selected. In the example given above,
	setting *fileIndexPtr to 2 would select the Igor Text file type on entry to the dialog.
	On exit from the dialog, *fileIndexPtr is set to the index of the file type string that
	the user last selected.
	
	initialDir can be "" or it can point to a full path to a directory. It determines the
	directory that will be initially displayed in the Save File dialog. If it is "", the
	directory will be the last directory that was seen in the Open or Save File dialogs.
	If initialDir points to a valid path to a directory, then this directory will be
	initially displayed in the dialog. On Macintosh, initialDir is a Macintosh HFS path
	using colons. On Windows, it is a Windows path using backslashes.
	
	defaultExtension points to the extension to be added to the file name if the user does
	not enter an extension. It does not include the leading dot. For example, pass "txt" to
	have ".txt" appended if the user does not enter an extension.
	
	XOPSaveFileDialog returns via filePath the full path to the file that the user chose
	or "" if the user cancelled. On Macintosh, filePath is a Macintosh HFS path using colons.
	On Windows, it is a Windows path using backslashes. filePath must point to a buffer of at
	least MAX_PATH_LEN+1 bytes.

	On Windows and Macintosh, the initial value of filePath sets the initial contents of
	the File Name edit control in the Save File dialog. The following values
	are valid:
		""
		a simple file name
		a full Mac or Win path to a file
	
	Thread Safety: XOPSaveFileDialog is not thread-safe.
*/
int
XOPSaveFileDialog(
	const char* prompt,
	const char* fileFilterStr,
	int* fileIndexPtr,
	const char* initialDir,
	const char* defaultExtension,			// Can be NULL
	char filePath[MAX_PATH_LEN+1])
{
	int err = 0;
	
	NSSavePanel* panel = [[NSSavePanel savePanel] retain];
	
	NSMutableArray* fileTypes = nil;
	int extensionCount = 0;
	if (strstr(fileFilterStr, "****") != NULL) {			// "All Files:****;" is in the filter string?
		if (defaultExtension!=NULL && *defaultExtension!=0) {
			// This should make defaultExtension the default extension but it appears that setAllowsOtherFileTypes:YES overrides that and ignores the default extension
			fileTypes = [NSMutableArray arrayWithCapacity:1];	// Auto-released
			NSString* defaultExtensionStr = [ NSString stringWithUTF8String:defaultExtension];		// Auto-released
			[ fileTypes addObject:defaultExtensionStr];
		}
		[panel setAllowsOtherFileTypes:YES];				// Allow all file types
	}
	else {
		fileTypes = [NSMutableArray arrayWithCapacity:10];	// Auto-released

		if (*defaultExtension != 0) {
			NSString* defaultExtensionStr = [ NSString stringWithUTF8String:defaultExtension];		// Auto-released
			[ fileTypes addObject:defaultExtensionStr];
		}

		const char* p = fileFilterStr;
		char extension[kMaxExtensionBytes+1];
		while(GetNextExtension(&p, extension)) {
			NSString* extensionStr = [ NSString stringWithUTF8String:extension];		// Auto-released
			[ fileTypes addObject:extensionStr];
		}
		
		extensionCount = [fileTypes count];
	}
	if (extensionCount > 0)
		[panel setAllowedFileTypes:fileTypes];
	
	NSString* titleStr = [NSString stringWithUTF8String:prompt];		// Auto-released
	[panel setTitle:titleStr];											// Copies titleStr
	
	if (*initialDir != 0) {
		char posixPath[MAX_PATH_LEN+1];
		int err2 = HFSToPosixPath(initialDir, posixPath, 1);
		if (err2 == 0) {
			NSURL* initialDirURL = [ NSURL fileURLWithFileSystemRepresentation:posixPath isDirectory:NO relativeToURL:nil ];	// Auto-released
			NSError* error;
			if ([initialDirURL checkResourceIsReachableAndReturnError:&error] == YES)
				[panel setDirectoryURL:initialDirURL];
		}
	}
	
	char proposedFileName[MAX_FILENAME_LEN+1];
	GetLeafName(filePath, proposedFileName);
	if (*proposedFileName != 0) {
		NSString* proposedFileNameStr = [NSString stringWithUTF8String:proposedFileName];		// Auto-released
		[panel setNameFieldStringValue:proposedFileNameStr];
	}
	
	NSInteger result = [panel runModal];
	if (result != NSFileHandlingPanelOKButton) {
		[panel release];
		return -1;										// Cancel
	}

	NSURL* fileURL = [panel URL];						// Auto-released
	CFStringRef ref = CFURLCopyFileSystemPath((CFURLRef)fileURL, kCFURLHFSPathStyle);
	NSString* hfsPathStr = (NSString*)ref;				// We own this
	const char* hfsPath = [ hfsPathStr UTF8String ];
	int len = (int)strlen(hfsPath);
	if (len > MAX_PATH_LEN)
		err = PATH_TOO_LONG;
	else
		strcpy(filePath, hfsPath);
	[hfsPathStr release];

	[panel release];
	
	return err;
}

/*	XOPSaveFileDialog2(flagsIn, prompt, fileFilterStr, fileFilterIndexPtr, initialDir, initialFile, flagsOutPtr, fullPathOut)

	Displays the Save File dialog.
	
	XOPSaveFileDialog2 requires Igor Pro 7.00 or later. With earlier versions,
	it returns an error. If your XOP must run with Igor6, use XOPSaveFileDialog instead.
	
	XOPSaveFileDialog2 returns 0 if the user chooses a file, or -1 if the user cancels,
	or another non-zero number in the event of an error.
	
	flagsIn is currently unused. Pass 0 for this parameter.
	
	prompt sets the dialog window title.
	
	fileFilterStr controls the filters in the file filter popup menu that appears in
	the Save File dialog. The construction of this string is the same as documented
	in the Igor help for the Open operation /F flag. For example, this populate the
	filter popup menu with three filters:
	
	const char* fileFilters = "Data Files (*.txt,*.dat,*.csv):.txt,.dat,.csv;" \
							  "HTML Files (*.htm,*.html):.htm,.html;" \
							  "All Files:.*;";
	
	fileFilterIndexPtr is ignored if it is NULL. If it is not NULL, then
	*fileFilterIndexPtr is the 1-based index of the file type filter to be initially
	selected. In the example given above, setting *fileFilterIndexPtr to 1 would select
	the "HTML Files" file filter on entry to the dialog. On exit from the dialog,
	*fileFilterIndexPtr is set to the 1-based index of the file filter string that
	the user last selected.
	
	initialDir can be "" or it can point to a full native path to a directory, with
	or without the trailing path separator. It determines the directory that will be
	initially displayed in the Open File dialog. If "", the directory will be the
	last directory that was seen in the Open File or Save File dialogs. initialDir
	is a native path using colons on Macintosh, backslashes on Windows.
	
	initialFile can be "" or it can be the name to which the File Name edit control
	in the Save File dialog is to be initialized.

	flagsOutPtr is currently unused. Pass NULL for this parameter.
	
	XOPSaveFileDialog2 returns, via fullPathOut, the full path to the file that the
	user chose. fullPathOut is a native path using colons on Macintosh, backslashes on Windows.
 
	Thread Safety: XOPSaveFileDialog2 is not thread-safe.
*/
int
XOPSaveFileDialog2(
	int flagsIn,						// Currently unused - must be 0
	const char* prompt,
	const char* fileFilterStr,
	int* fileFilterIndexPtr,			// Can be NULL
	const char* initialDir,
	const char* initialFile,
	int* flagsOutPtr,					// Currently unused - must be NULL
	char fullPathOut[MAX_PATH_LEN+1])
{
	return (int)CallBack8(XOP_SAVE_FILE_DIALOG_2, XOP_CALLBACK_INT(flagsIn), (void*)prompt, (void*)fileFilterStr, fileFilterIndexPtr, (void*)initialDir, (void*)initialFile, flagsOutPtr, fullPathOut);
}
