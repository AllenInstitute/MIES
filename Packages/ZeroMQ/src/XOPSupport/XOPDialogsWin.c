/*	This file contains the Windows implemention of cross-platform utility dialogs.

	If you are porting an XOP that creates dialogs to XOP Toolkit 7 from
	an earlier version, see the section on dialogs in Appendix A of the
	XOP Toolkit 7 manual.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	XOPEmergencyAlert(message)
	
	This routine used by the XOP Toolkit for dire emergencies only.
	You should not need it. Use XOPOKAlert instead.
	
	Thread Safety: XOPEmergencyAlert is not thread-safe.
*/
void
XOPEmergencyAlert(const char* message)
{
	MessageBox(NULL, message, "Emergency", MB_OK);
}

/*	XOPOKAlert(title, message)
	
	Thread Safety: XOPOKAlert is not thread-safe.
*/
void
XOPOKAlert(const char* title, const char* message)
{
	if (!CheckRunningInMainThread("XOPOKAlert"))
		return;

	MessageBox(IgorClientHWND(), (char*)message, (char*)title, MB_OK);
}

/*	XOPOKCancelAlert(title, message)

	Returns 1 for OK, -1 for cancel.
	
	Thread Safety: XOPOKCancelAlert is not thread-safe.
*/
int
XOPOKCancelAlert(const char* title, const char* message)
{
	int result;

	if (!CheckRunningInMainThread("XOPOKCancelAlert"))
		return -1;

	
	result = MessageBox(IgorClientHWND(), (char*)message, (char*)title, MB_OKCANCEL);
	if (result == IDOK)
		return 1;
	return -1;
}

/*	XOPYesNoAlert(title, message)

	Returns 1 for yes, 2 for no.
	
	Thread Safety: XOPYesNoAlert is not thread-safe.
*/
int
XOPYesNoAlert(const char* title, const char* message)
{
	int result;
	
	if (!CheckRunningInMainThread("XOPYesNoAlert"))
		return 2;

	result = MessageBox(IgorClientHWND(), (char*)message, (char*)title, MB_YESNO);
	if (result == IDYES)
		return 1;
	return 2;
}

/*	XOPYesNoCancelAlert(title, message)

	Returns 1 for yes, 2 for no, -1 for cancel.
	
	Thread Safety: XOPYesNoCancelAlert is not thread-safe.
*/
int
XOPYesNoCancelAlert(const char* title, const char* message)
{
	int result;
	
	if (!CheckRunningInMainThread("XOPYesNoCancelAlert"))
		return -1;

	result = MessageBox(IgorClientHWND(), (char*)message, (char*)title, MB_YESNOCANCEL);
	if (result == IDYES)
		return 1;
	if (result == IDNO)
		return 2;
	return -1;
}

/*	PositionWinDialogWindow(theDialog, refWindow)

	Positions the dialog nicely relative to the reference window.

	If refWindow is NULL, it uses the Igor MDI client window. You should pass
	NULL for refWindow unless this is a second-level dialog that you want to
	position nicely relative to the first-level dialog. In that case, pass the
	HWND for the first-level dialog.
	
	Thread Safety: PositionWinDialogWindow is not thread-safe.
*/
void
PositionWinDialogWindow(HWND theDialog, HWND refWindow)
{
	WINDOWPLACEMENT wp;
	RECT childRECT, refRECT;
	int width, height;
	
	if (refWindow == NULL)
		refWindow = IgorClientHWND();
	GetWindowRect(refWindow, &refRECT);

	wp.length = sizeof(wp);
	GetWindowPlacement(theDialog, &wp);
	
	childRECT = wp.rcNormalPosition;
	width = childRECT.right - childRECT.left;
	height = childRECT.bottom - childRECT.top;
	
	childRECT.top = refRECT.top + 20;
	childRECT.bottom = childRECT.top + height;
	childRECT.left = (refRECT.left + refRECT.right)/2 - width/2;
	childRECT.right = childRECT.left + width;
	
	#if 0
	{
		/*	HR, 2013-02-26, XOP Toolkit 6.30: This did not work with multiple monitors
			if Igor was on the second monitor because, among other things, GetSystemMetrics
			returns information about the main screen only. There is no simple solution
			for this so I have removed this check altogether.
		*/

		// Make sure window remains on screen.
	
		int screenWidth = GetSystemMetrics(SM_CXFULLSCREEN);
		int screenHeight = GetSystemMetrics(SM_CYFULLSCREEN);

		if (childRECT.left < 0) {
			childRECT.left = 0;
			childRECT.right = width;
		}
		if (childRECT.right > screenWidth) {
			childRECT.right = screenWidth;
			childRECT.left = screenWidth - width;
		}
		if (childRECT.bottom > screenHeight) {
			childRECT.bottom = screenHeight;
			childRECT.top = screenHeight - height;
		}
	}
	#endif

	wp.flags = 0;
	wp.rcNormalPosition = childRECT;
	SetWindowPlacement(theDialog, &wp);
}

static UINT_PTR APIENTRY	// Hook for open or save file dialogs.
OpenOrSaveFileNameHook(HWND hdlg, UINT uiMsg, WPARAM wParam, LPARAM lParam)
{	
	HWND hMainDlg;
	
	/*	Because we use the OFN_EXPLORER flag and we specify a hook function, Windows
		creates a child dialog for us and the hdlg parameter to this hook is the child
		dialog.
	*/
	hMainDlg = GetParent(hdlg);
	if (hMainDlg == NULL)
		return 0;

	switch(uiMsg) {
		case WM_INITDIALOG:
			/*	HR, 090121, XOPSupport 5.09: Because we now use OFN_ENABLESIZING, the OS positions
				sizes the dialog. However, without this hook, the dialog initially comes up in the top/left
				corner of the frame window. Therefore I decided to leave the hook in. After this hook
				positions the window, the OS repositions and resizes it which may cause a brief flash.
			*/
			PositionWinDialogWindow(hMainDlg, NULL);
			break;
	}
	return 0;			// Let default dialog box procedure process the message.
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
	OPENFILENAME ofn;
	char filePath2[MAX_PATH_LEN+1];
	char initialDir2[MAX_PATH_LEN+1];

	if (!CheckRunningInMainThread("XOPOpenFileDialog"))
		return NOT_IN_THREADSAFE;
	
	if (*fileFilterStr == 0)
		fileFilterStr = "All Files (*.*)\0*.*\0\0";
		
	if (*initialDir == 0) {
		GetStandardFileWinPath(initialDir2);	// Get Igor's Open File dialog directory.
	}
	else {
		strcpy(initialDir2, initialDir);
		SetStandardFileWinPath(initialDir);		// Sets initial directory for next Open File dialog. This will be overridden below, but not if the user cancels.
	}
		
	/*	HR, 040928, XOP Toolkit 5.04
		Previously this copied filePath to filePath2. This was correct because the filePath parameter
		was supposed to be either "" or just the proposed file name. However, I incorrectly passed
		a full path for the filePath parameter in all of the sample XOPs. This mistake undoubtedly
		leaked into users' XOPs. Therefore I now allow filePath to be either "", just a file name,
		or a full path.
	*/
	// strcpy(filePath2, filePath);				// HR, 010815: Previously filePath2 was set to "" which prevented the File Name item in the Windows Open File dialog from being preset as the comment above says it should be.
	GetLeafName(filePath, filePath2);

	MemClear(&ofn, sizeof(ofn));
	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = IgorClientHWND();
	ofn.lpstrFile = filePath2;
	ofn.nMaxFile = MAX_PATH_LEN+1;
	ofn.lpstrFilter = fileFilterStr;
	ofn.nFilterIndex = fileIndexPtr==NULL ? 1 : *fileIndexPtr;
	ofn.lpstrTitle = prompt;
	ofn.lpstrFileTitle = NULL;
	ofn.lpstrInitialDir = initialDir2;
	ofn.lpfnHook = OpenOrSaveFileNameHook;		// Needed to set position of the dialog. Otherwise, it is in top/left corner of screen.
	ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
	ofn.Flags |= OFN_EXPLORER;
	ofn.Flags |= OFN_ENABLEHOOK;				// Needed so that hook will be called.
	ofn.Flags |= OFN_ENABLESIZING;				// HR, 090121: Added this to get resizeable dialog.
	ofn.Flags |= OFN_HIDEREADONLY;
	ofn.Flags |= OFN_NOCHANGEDIR;				// Changing the current directory causes problems. e.g., if set to floppy disk and the floppy is removed, the system slows down.

	if (GetOpenFileName(&ofn) == 0) {
		int err;
		err = CommDlgExtendedError();			// err will be zero if cancel.
		if (err == 0)
			return -1;

		// We got an error other than cancel.
		*filePath2 = 0;							// HR, 021114: Clear possible bad fields
		*initialDir2 = 0;						// and try again.
		if (GetOpenFileName(&ofn) != 0) {		// Succeeded this time?
			err = 0;
		}
		else {
			if (CommDlgExtendedError() == 0)
				return -1;						// User canceled.
			
			// Report the original error.
			err = WindowsErrorToIgorError(err);
			IgorError("XOPOpenFileDialog", err);
			return err;
		}
	}
	
	if (fileIndexPtr != NULL)
		*fileIndexPtr = ofn.nFilterIndex;
	
	strcpy(filePath, filePath2);
	SetStandardFileWinPath(filePath);			// Update Igor's Open File dialog directory.

	return 0;
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
	const char* fileFilterStr, int* fileIndexPtr,
	const char* initialDir,
	const char* defaultExtensionStr,
	char filePath[MAX_PATH_LEN+1])
{
	OPENFILENAME ofn;
	char filePath2[MAX_PATH_LEN+1];
	char initialDir2[MAX_PATH_LEN+1];
	
	if (!CheckRunningInMainThread("XOPSaveFileDialog"))
		return NOT_IN_THREADSAFE;
	
	if (*fileFilterStr == 0)
		fileFilterStr = "Text Files (*.txt)\0*.txt\0\0";
		
	if (*initialDir == 0) {
		GetStandardFileWinPath(initialDir2);	// Get Igor's Save File dialog directory.
	}
	else {
		strcpy(initialDir2, initialDir);
		SetStandardFileWinPath(initialDir);		// Sets initial directory for next Save File dialog. This will be overridden below, but not if the user cancels.
	}
		
	/*	HR, 040928, XOP Toolkit 5.04
		Previously this copied filePath to filePath2. This was correct because the filePath parameter
		was supposed to be either "" or just the proposed file name. However, I incorrectly passed
		a full path for the filePath parameter in all of the sample XOPs. This mistake undoubtedly
		leaked into users' XOPs. Therefore I now allow filePath to be either "", just a file name,
		or a full path.
	*/
	// strcpy(filePath2, filePath);				// HR, 010815: Previously filePath2 was set to "" which prevented the File Name item in the Windows Open File dialog from being preset as the comment above says it should be.
	GetLeafName(filePath, filePath2);

	MemClear(&ofn, sizeof(ofn));
	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = IgorClientHWND();
	ofn.lpstrFile = filePath2;
	ofn.nMaxFile = MAX_PATH_LEN+1;
	ofn.lpstrFilter = fileFilterStr;
	ofn.nFilterIndex = fileIndexPtr==NULL ? 1 : *fileIndexPtr;
	ofn.lpstrDefExt = defaultExtensionStr;
	ofn.lpstrTitle = prompt;
	ofn.lpstrFileTitle = NULL;
	ofn.lpstrInitialDir = initialDir2;
	ofn.lpfnHook = OpenOrSaveFileNameHook;		// Needed to set position of the dialog. Otherwise, it is in top/left corner of screen.
	ofn.Flags = OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT;
	ofn.Flags |= OFN_EXPLORER;
	ofn.Flags |= OFN_ENABLEHOOK;				// Needed so that hook will be called.
	ofn.Flags |= OFN_ENABLESIZING;				// HR, 090121: Added this to get resizeable dialog.
	ofn.Flags |= OFN_HIDEREADONLY;
	ofn.Flags |= OFN_NOCHANGEDIR;				// Changing the current directory causes problems. e.g., if set to floppy disk and the floppy is removed, the system slows down.

	if (GetSaveFileName(&ofn) == 0) {
		int err;
		err = CommDlgExtendedError();			// err will be zero if cancel.
		if (err == 0)
			return -1;

		// We got an error other than cancel.
		*filePath2 = 0;							// HR, 021114: Clear possible bad fields
		*initialDir2 = 0;						// and try again.
		if (GetSaveFileName(&ofn) != 0) {		// Succeeded this time?
			err = 0;
		}
		else {
			if (CommDlgExtendedError() == 0)
				return -1;						// User canceled.
			
			// Report the original error.
			err = WindowsErrorToIgorError(err);
			IgorError("XOPSaveFileDialog", err);
			return err;
		}
	}
	
	if (fileIndexPtr != NULL)
		*fileIndexPtr = ofn.nFilterIndex;
	
	strcpy(filePath, filePath2);
	SetStandardFileWinPath(filePath);			// Update Igor's open file dialog directory.

	return 0;
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

