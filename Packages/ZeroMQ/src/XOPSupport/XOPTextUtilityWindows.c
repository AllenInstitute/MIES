/*	XOPTextUtilityWindows.c

	This file contains the text utility ("TU") routines used to create a text editing window in Igor.
	It also contains the History routines used to access and the history area.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

// TUNew is obsolete and was removed from XOP Toolkit 6. Use TUNew2.

/*	TUNew2(winTitle, winRectPtr, TUPtr, windowRefPtr)

	TUNew2 creates a new text window and TU document.
	
	winTitle points to the title for the new window.
	
	winRectPtr points to a Macintosh Rect which specifies the size and location of
	the content region of the window in units of pixels.
	
	On Macintosh, this is in global coordinates.  Use a top coordinate of 40 to position
	the window right below the menu bar.
	
	On Windows, it is in client window coordinates of the Igor MDI frame window. Use a
	top coordinate of 22 to position the window right below the menu bar.
	
	It returns via TUPtr a handle to the TU document and returns via windowRefPtr
	a pointer to a WindowPtr (Mac) or HWND (Windows) for the newly created window.
	
	In the event of an error, it returns non-zero as the function result and NULL via
	TUPtr and windowRefPtr.

	TUNew2 uses a default font and font size. The resulting text document is like
	an Igor plain text notebook.
	
	The window is initially hidden. Call ShowAndActivateXOPWindow to show it.
	
	Thread Safety: TUNew2 is not thread-safe.
*/
int
TUNew2(const char* winTitle, const Rect* winRectPtr, Handle* TUPtr, IgorWindowRef* windowRefPtr)
{
	int err;

	*TUPtr = NULL;
	*windowRefPtr = NULL;

	if (!CheckRunningInMainThread("TUNew2"))
		return NOT_IN_THREADSAFE;

	err = (int)CallBack4(TUNEW2, (void*)winTitle, (void*)winRectPtr, TUPtr, windowRefPtr);
	return err;
}
	
/*	TUDispose(TU)

	TUDispose disposes of the TE record, the window, and the TU record for the specified
	TU window. This should be called for any TU windows when the XOP is about to be disposed.
	
	Thread Safety: TUDispose is not thread-safe.
*/
void	
TUDispose(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUDispose"))
		return;

	CallBack1(TUDISPOSE, TU);
}
	
/*	TUDisplaySelection(TU)

	Tries to get the selected text in view as best as it can by scrolling.
	
	The rules for vertical scrolling used by TUSelToView are:
		if selStart and selEnd are in view, do nothing
		if selected text won't fit in window vertically
			bring selStart line to top of window
		if selected text will fit vertically
			if selStart line is above
				bring selStart line to top
			if selEnd is below
				bring selEnd line to bottom
	
	If the selected text is multiline, it won't scroll horizontally to get the right edge in
	view.  This gives best intuitive results.
	
	Thread Safety: TUDisplaySelection is not thread-safe.
*/
void
TUDisplaySelection(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUDisplaySelection"))
		return;

	CallBack1(TUDISPLAYSELECTION, TU);
}

/*	TUGrow(TU, size)
	
	TUGrow() adjust the window size.

	Size is the size of the window packed into a 32 bit integer.
	
	The vertical size is in the high word and the horizontal size is in the low word.
	
	However, if size = 0 then it does a zoom rather than a grow.
	
	Also, if size == -1, then TUGrow does not resize the window but merely adjusts
	for a change in size that has already been done. For example, TUGrow moves
	the scroll bars to the new edges of the window.
	
	Thread Safety: TUGrow is not thread-safe.
*/
void
TUGrow(TUStuffHandle TU, int size)
{	
	if (!CheckRunningInMainThread("TUGrow"))
		return;

	CallBack2(TUGROW, TU, XOP_CALLBACK_INT(size));
}

/*	TUDrawWindow(TU)

	Draws the window containing the text referred to by TU.
	
	Thread Safety: TUDrawWindow is not thread-safe.
*/
void
TUDrawWindow(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUDrawWindow"))
		return;

	CallBack1(TUDRAWWINDOW, TU);
}

/*	TUUpdate(TU)

	Updates the window containing the text referred to by TU if the updateRgn of the window
	is not empty.
	
	Thread Safety: TUUpdate is not thread-safe.
*/
void
TUUpdate(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUUpdate"))
		return;

	CallBack1(TUUPDATE, TU);
}

/*	TUFind(TU, messageCode)

	messageCode is the message sent by Igor to the TU window. It is one of the following:
		kXOPWindowMessageFind
		kXOPWindowMessageFindSame
		kXOPWindowMessageFindSameBackwards
		kXOPWindowMessageFindSelection
		kXOPWindowMessageFindSelectionBackwards
		kXOPWindowMessageUseSelectionForFind
	
	Thread Safety: TUFind is not thread-safe.
*/
void
TUFind(TUStuffHandle TU, int messageCode)
{	
	if (!CheckRunningInMainThread("TUFind"))
		return;

	CallBack2(TUFIND, TU, XOP_CALLBACK_INT(messageCode));
}

/*	TUReplace(TU)
	
	Thread Safety: TUReplace is not thread-safe.
*/
void
TUReplace(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUReplace"))
		return;

	CallBack1(TUREPLACE, TU);
}

/*	TUIndentLeft(TU)
	
	Thread Safety: TUIndentLeft is not thread-safe.
*/
void
TUIndentLeft(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUIndentLeft"))
		return;

	CallBack1(TUINDENTLEFT, TU);
}

/*	TUIndentRight(TU)
	
	Thread Safety: TUIndentRight is not thread-safe.
*/
void
TUIndentRight(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUIndentRight"))
		return;

	CallBack1(TUINDENTRIGHT, TU);
}

/*	TUClick(TU, merP)

	Services click referred to by merP.
	
	Thread Safety: TUClick is not thread-safe.
*/
void
TUClick(TUStuffHandle TU, WMMouseEventRecord* merP)
{	
	if (!CheckRunningInMainThread("TUClick"))
		return;

	CallBack2(TUCLICK, TU, merP);
}

/*	TUActivate(TU)
	
	Thread Safety: TUActivate is not thread-safe.
*/
void
TUActivate(TUStuffHandle TU, int flag)
{	
	if (!CheckRunningInMainThread("TUActivate"))
		return;

	CallBack2(TUACTIVATE, TU, XOP_CALLBACK_INT(flag));
}

/*	TUIdle(TU)
	
	Thread Safety: TUIdle is not thread-safe.
*/
void
TUIdle(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUIdle"))
		return;

	CallBack1(TUIDLE, TU);
}

/*	TUNull(TU)
	
	Thread Safety: TUNull is not thread-safe.
*/
void
TUNull(TUStuffHandle TU, WMMouseEventRecord* merP)
{	
	if (!CheckRunningInMainThread("TUNull"))
		return;

	CallBack2(TUNULL, TU, merP);
}

/*	TUCopy(TU)
	
	Thread Safety: TUCopy is not thread-safe.
*/
void
TUCopy(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUCopy"))
		return;

	CallBack1(TUCOPY, TU);
}

/*	TUCut(TU)
	
	Thread Safety: TUCut is not thread-safe.
*/
void
TUCut(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUCut"))
		return;

	CallBack1(TUCUT, TU);
}

/*	TUPaste(TU)
	
	Thread Safety: TUPaste is not thread-safe.
*/
void
TUPaste(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUPaste"))
		return;

	CallBack1(TUPASTE, TU);
}

/*	TUClear(TU)
	
	Thread Safety: TUClear is not thread-safe.
*/
void
TUClear(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUClear"))
		return;

	CallBack1(TUCLEAR, TU);
}

/*	TUKey(TU, eventPtr)
	
	Thread Safety: TUKey is not thread-safe.
*/
void
TUKey(TUStuffHandle TU, WMKeyboardEventRecord* eventPtr)
{	
	if (!CheckRunningInMainThread("TUKey"))
		return;

	CallBack2(TUKEY, TU, eventPtr);
}

/*	TUInsert(TU)
	
	Thread Safety: TUInsert is not thread-safe.
*/
void
TUInsert(TUStuffHandle TU, const char *dataPtr, int dataLen)
{	
	if (!CheckRunningInMainThread("TUInsert"))
		return;

	CallBack3(TUINSERT, TU, (void*)dataPtr, XOP_CALLBACK_INT(dataLen));
}

/*	TUDelete(TU)
	
	Thread Safety: TUDelete is not thread-safe.
*/
void
TUDelete(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUDelete"))
		return;

	CallBack1(TUDELETE, TU);
}

// TUSetSelect is obsolete and was removed from XOP Toolkit 6. Use TUSetSelLocs instead.

/*	TUSelectAll(TU)
	
	Thread Safety: TUSelectAll is not thread-safe.
*/
void
TUSelectAll(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUSelectAll"))
		return;

	CallBack1(TUSELECTALL, TU);
}

/*	TUUndo(TU)
	
	Thread Safety: TUUndo is not thread-safe.
*/
void
TUUndo(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUUndo"))
		return;

	CallBack1(TUUNDO, TU);
}

/*	TUPrint(TU)
	
	Thread Safety: TUPrint is not thread-safe.
*/
void
TUPrint(TUStuffHandle TU)
{	
	if (!CheckRunningInMainThread("TUPrint"))
		return;

	CallBack1(TUPRINT, TU);
}

/*	TUFixEditMenu(TU)

	Sets items in edit menu properly according to the state of the TU document.
	
	Thread Safety: TUFixEditMenu is not thread-safe.
*/
void
TUFixEditMenu(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUFixEditMenu"))
		return;

	CallBack1(TUFIXEDITMENU, TU);
}

/*	TUFixFileMenu(TU)

	Sets items in file menu properly according to the state of the TU document.
	
	Thread Safety: TUFixFileMenu is not thread-safe.
*/
void
TUFixFileMenu(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUFixFileMenu"))
		return;

	CallBack1(TUFIXFILEMENU, TU);
}

// TUGetText is obsolete and was removed from XOP Toolkit 6. Use TUFetchParagraphText instead.

// TUFetchText is obsolete and was removed from XOP Toolkit 6. Use TUFetchParagraphText instead.

// TULength is obsolete and was removed from XOP Toolkit 6. Use TUGetDocInfo instead.

/*	TULines(TU)

	TULines returns the number of lines in the specified document.
	
	Thread Safety: TULines is not thread-safe.
*/
int
TULines(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TULines"))
		return 0;

	return (int)CallBack1(TULINES, TU);
}

// TUSelStart is obsolete and was removed from XOP Toolkit 6. Use TUGetSelLocs instead.

// TUSelEnd is obsolete and was removed from XOP Toolkit 6. Use TUGetSelLocs instead.

// TUSelectionLength is obsolete and was removed from XOP Toolkit 6. Use TUGetSelLocs instead.

// TUInsertFile is obsolete and was removed from XOP Toolkit 6. There is no direct replacement.

// TUWriteFile is obsolete and was removed from XOP Toolkit 6. There is no direct replacement.

/*	TUSFInsertFile(TU, prompt, fileTypes, numTypes)

	Gets file from user using Open File dialog.

	prompt is a prompt to appear in Open File dialog.
	
	fileTypes is a pointer to an OSType array of file types.
	
	numTypes is the number of file types in the array.
	
	Inserts text from the file at the insertion point of the specified document.
	Returns error code from insertion.
	
	Thread Safety: TUSFInsertFile is not thread-safe.
*/
int
TUSFInsertFile(TUStuffHandle TU, const char *prompt, OSType fileTypes[], int numTypes)
{	
	if (!CheckRunningInMainThread("TUSFInsertFile"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUSFINSERTFILE, TU, (void*)prompt, fileTypes, XOP_CALLBACK_INT(numTypes));
}

/*	TUSFWriteFile(TU, prompt, fileType, allFlag)

	Gets file name from user using the Save File dialog.
	
	Writes text from the specified document to file. Replaces file if it already exists.
	
	prompt is a prompt to appear in Save File dialog.
	
	fileType is type of file to be written (e.g. 'TEXT').
	
	In Igor6, allFlag = 0 means write only selected text. Otherwise, write all text.
	In Igor7, TUSFWriteFile ignores the allFlag parameter and always writes the entire file.
	If you rely on writing the selection only, you can do it by getting the window's
	text using TUFetchSelectedText and then writing to a file using XOPWriteFile.
	
	Returns error code from write.
	
	Thread Safety: TUSFWriteFile is not thread-safe.
*/
int
TUSFWriteFile(TUStuffHandle TU, const char *prompt, OSType fileType, int allFlag)
{	
	if (!CheckRunningInMainThread("TUSFWriteFile"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUSFWRITEFILE, TU, (void*)prompt, XOP_CALLBACK_INT(fileType), XOP_CALLBACK_INT(allFlag));
}

/*	TUPageSetupDialog(TU)
	
	Thread Safety: TUPageSetupDialog is not thread-safe.
*/
void
TUPageSetupDialog(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUPageSetupDialog"))
		return;

	CallBack1(TUPAGESETUPDIALOG, TU);
}

/*	TUGetDocInfo(TU, dip)
	
	Returns information about the text utility document via the structure pointed to by dip.
	You MUST execute
		dip->version = TUDOCINFO_VERSION
	before calling TUGetDocInfo so that Igor knows which version of the structure
	your XOP is using.
	
	Returns 0 if OK, -1 if unsupported version of the structure or an Igor error
	code if the version of Igor that is running does not support this callback.
	
	Thread Safety: TUGetDocInfo is not thread-safe.
*/
int
TUGetDocInfo(TUStuffHandle TU, TUDocInfoPtr dip)
{
	if (!CheckRunningInMainThread("TUGetDocInfo"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack2(TUGETDOCINFO, TU, dip);
}

/*	TUGetSelLocs(TU, startLocPtr, endLocPtr)

	Sets *startLocPtr and *endLocPtr to describe the selected text in the document.

	Returns 0 if OK, an Igor error code if the version of Igor that you are running
	with does not support this callback.
	
	Thread Safety: TUGetSelLocs is not thread-safe.
*/
int
TUGetSelLocs(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr)
{
	if (!CheckRunningInMainThread("TUGetSelLocs"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack3(TUGETSELLOCS, TU, startLocPtr, endLocPtr);
}

/*	TUSetSelLocs(TU, startLocPtr, endLocPtr, flags)

	If startLocPtr is not NULL, sets the selection in the text utility document
	based on startLocPtr and endLocPtr which must be valid.
	
	If flags is 1, displays the selection if it is out of view.
	Other bits in flags may be used for other purposes in the future.

	Returns 0 if OK, an Igor error code if the version of Igor that you are running
	with does not support this callback. Also returns an error if the start or
	end locations are out of bounds or if the start location is after the end location.
	
	Thread Safety: TUSetSelLocs is not thread-safe.
*/
int
TUSetSelLocs(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr, int flags)
{
	if (!CheckRunningInMainThread("TUSetSelLocs"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUSETSELLOCS, TU, startLocPtr, endLocPtr, XOP_CALLBACK_INT(flags));
}

/*	TUFetchParagraphText(TU, paragraph, textPtrPtr, lengthPtr)
	
	If textPtrPtr is not NULL, returns via textPtrPtr the text in the specified paragraph.
	
	Sets *lengthPtr to the number of characters in the paragraph whether textPtrPtr is NULL or not.
	
	paragraph is assumed to be a valid paragraph number.
	
	textPtrPtr is a pointer to your char* variable.
	Igor allocates a pointer, using WMNewPtr, and sets *textPtrPtr to point to the allocated memory.
	The returned pointer belongs to you. Dispose it using WMDisposePtr when you no longer need it.
	
	Example:
		char* p;
		int paragraph, length;
		int result;
		
		paragraph = 0;
		if (result = TUFetchParagraphText(TU, paragraph, &p, &length))
			return result;
		
		<Deal with the text>
		
		WMDisposePtr(p);
	
	Note that the text pointed to by p is NOT null terminated and therefore
	is not a C string. You can turn it into a C string as follows:
		result = WMSetPtrSize(p, length+1);
		if (result != 0) {
			WMDisposePtr(p);
			return result
		}
		p[length] = 0;

	Returns 0 if OK, an Igor error code if an error occurs fetching the text
	or the version of Igor that you are running with does not support this callback.
	Also returns an error if the paragraph is out of bounds.
	
	Thread Safety: TUFetchParagraphText is not thread-safe.
*/
int
TUFetchParagraphText(TUStuffHandle TU, int paragraph, Ptr *textPtrPtr, int *lengthPtr)
{
	if (!CheckRunningInMainThread("TUFetchParagraphText"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUFETCHPARAGRAPHTEXT, TU, XOP_CALLBACK_INT(paragraph), textPtrPtr, lengthPtr);
}

/*	TUFetchSelectedText(TU, textHandlePtr, reservedForFuture, flags)
	
	Returns via textHandlePtr the selected text in the text utility document.
	
	textHandlePtr is a pointer to your Handle variable.
	reservedForFuture should be NULL for now.
	flags should be 0 for now.
	
	Example:
		Handle h;
		int result;
		
		if (result = TUFetchSelectedText(TU, &h, NULL, 0))
			return result;
		
		<Deal with the text>
		
		WMDisposeHandle(h);
	
	Note that the text in the handle h is NOT null terminated and therefore
	is not a C string. You can turn it into a C string as follows:
		length = WMGetHandleSize(h);
		result = WMSetHandleSize(h, length+1);
		if (result != 0) {
			WMDisposeHandle(h);
			return result
		}
		*h[length] = 0;

	Returns 0 if OK, an Igor error code if an error occurs fetching the text
	or the version of Igor that you are running with does not support this callback.
	
	Thread Safety: TUFetchSelectedText is not thread-safe.
*/
int
TUFetchSelectedText(TUStuffHandle TU, Handle* textHandlePtr, void* reservedForFuture, int flags)
{
	if (!CheckRunningInMainThread("TUFetchSelectedText"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUFETCHSELECTEDTEXT, TU, textHandlePtr,  reservedForFuture, XOP_CALLBACK_INT(flags));
}

/*	TUFetchText2(TU, startLocPtr, endLocPtr, textHandlePtr, reservedForFuture, flags)
	
	Returns via textHandlePtr the text in the text utility document from
	the start location to the end location.
	
	If startLocPtr is NULL, the start of the document is used as the start location.
	
	If endLocPtr is NULL, the end of the document is used as the end location.
	
	textHandlePtr is a pointer to your Handle variable.
	
	reservedForFuture must be NULL for now.
	
	flags should be 0 for now.
	
	Example:
		Handle h;
		int result;
		
		if (result = TUFetchText2(TU, NULL, NULL, &h, NULL, 0))	// Fetch all text in document
			return result;
		
		<Deal with the text>
		
		WMDisposeHandle(h);
	
	Note that the text in the handle h is NOT null terminated and therefore
	is not a C string. You can turn it into a C string as follows:
		length = WMGetHandleSize(h);
		result = WMSetHandleSize(h, length+1);
		if (result != 0) {
			WMDisposeHandle(h);
			return result
		}
		*h[length] = 0;

	Returns 0 if OK, an Igor error code if an error occurs fetching the text
	or the version of Igor that you are running with does not support this callback.
	
	Added in Igor Pro 6.20 but works with any version.
	
	Thread Safety: TUFetchText2 is not thread-safe.
*/
int
TUFetchText2(TUStuffHandle TU, TULocPtr startLocPtr, TULocPtr endLocPtr, Handle* textHandlePtr, void* reservedForFuture, int flags)
{
	if (!CheckRunningInMainThread("TUFetchText2"))
		return NOT_IN_THREADSAFE;
		
	if (igorVersion < 620) {				// Emulate for old versions of Igor
		TULoc saveStartLoc, saveEndLoc;
		TULoc startLoc, endLoc;
		int err;

		TUGetSelLocs(TU, &saveStartLoc, &saveEndLoc);
		
		if (startLocPtr == NULL) {
			startLoc.paragraph = 0;
			startLoc.pos = 0;
		}
		else {
			startLoc = *startLocPtr;
		}
		
		if (endLocPtr == NULL) {
			TUDocInfo di;
			int length;
			
			di.version = TUDOCINFO_VERSION;
			if (err = TUGetDocInfo(TU, &di))
				return err;
			endLoc.paragraph = di.paragraphs-1;
				
			if (err = TUFetchParagraphText(TU, endLoc.paragraph, NULL, &length))
				return err;
			endLoc.pos = length;
		}
		else {
			endLoc = *endLocPtr;
		}

		if (err = TUSetSelLocs(TU, &startLoc, &endLoc, 0))
			return err;
		
		err = TUFetchSelectedText(TU, textHandlePtr, NULL, 0);

		TUSetSelLocs(TU, &saveStartLoc, &saveEndLoc, 0);

		return err;
	}

	return (int)CallBack6(TUFETCHTEXT2, TU, startLocPtr, endLocPtr, textHandlePtr,  reservedForFuture, XOP_CALLBACK_INT(flags));
}

/*	TUSetStatusArea(TU, message, eraseFlags, statusAreaWidth)

	If message is not NULL, sets the status message in the text utility document.
	message is a C string. Only the first 127 characters are displayed.
	
	If message is not NULL then eraseFlags determines when the status
	message will be erased. See the TU_ERASE_STATUS #defines in IgorXOP.h.
	
	In Igor6, if statusAreaWidth is >= 0, it sets the width of the status area in pixels.
	In Igor7, the status area is always the full width of the window and the statusAreaWidth
	parameter is ignored.

	Returns 0 if OK, an Igor error code if the version of Igor that you are running
	with does not support this callback.
	
	Thread Safety: TUSetStatusArea is not thread-safe.
*/
int
TUSetStatusArea(TUStuffHandle TU, const char* message, int eraseFlags, int statusAreaWidth)
{
	if (!CheckRunningInMainThread("TUSetStatusArea"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack4(TUSETSTATUSAREA, TU, (void*)message,  XOP_CALLBACK_INT(eraseFlags), XOP_CALLBACK_INT(statusAreaWidth));
}

/*	TUMoveToPreferredPosition(TUStuffHandle TU)

	Moves the window to the preferred position, as determined by the user's notebook
	preferences. Normally, you will call this in response to the MOVE_TO_PREFERRED_POSITION
	message from IGOR.
	
	During the TUMoveToPreferredPosition call, your XOP will receive a GROW message from IGOR.
	On Windows, your window procedure may also receive several messages from the operating system.
	
	Thread Safety: TUMoveToPreferredPosition is not thread-safe.
*/
void
TUMoveToPreferredPosition(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUMoveToPreferredPosition"))
		return;

	CallBack1(TUMOVE_TO_PREFERRED_POSITION, TU);
}

/*	TUMoveToFullSizePosition(TUStuffHandle TU)

	Moves the window to show all of its content or to fill the screen (Macintosh) or
	MDI frame window (Windows). Normally, you will call this in response to the
	MOVE_TO_FULLSIZE_POSITION message from IGOR.
	
	During the TUMoveToFullSizePosition call, your XOP will receive a GROW message from IGOR.
	On Windows, your window procedure may also receive several messages from the operating system.
	
	Thread Safety: TUMoveToFullSizePosition is not thread-safe.
*/
void
TUMoveToFullSizePosition(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TUMoveToFullSizePosition"))
		return;

	CallBack1(TUMOVE_TO_FULL_POSITION, TU);
}

/*	TURetrieveWindow(TUStuffHandle TU)

	Moves the window, if necessary, to fit entirely within the screen (Macintosh) or
	MDI frame window (Windows). Normally, you will call this in response to the
	RETRIEVE message from IGOR.
	
	During the TURetrieveWindow call, your XOP will receive a GROW message from IGOR.
	On Windows, your window procedure may also receive several messages from the operating system.
	
	Thread Safety: TURetrieveWindow is not thread-safe.
*/
void
TURetrieveWindow(TUStuffHandle TU)
{
	if (!CheckRunningInMainThread("TURetrieveWindow"))
		return;

	CallBack1(TURETRIEVE, TU);
}

/*	HistoryDisplaySelection()

	Scrolls the current selection in the history area into view.
	
	Thread Safety: HistoryDisplaySelection is not thread-safe.
*/
void
HistoryDisplaySelection(void)
{
	if (!CheckRunningInMainThread("HistoryDisplaySelection"))
		return;

	CallBack0(HISTORY_DISPLAYSELECTION);
}

/*	HistoryInsert()

	Inserts the specified text into the history area, replacing the current selection, if any.
	
	If you just want to append text to the history, call XOPNotice or XOPNotice2 instead of
	HistoryInsert.
	
	Except in very rare cases you should not modify the history, except to append to it.
	
	Thread Safety: HistoryInsert is not thread-safe.
*/
void
HistoryInsert(const char* dataPtr, int dataLen)
{
	if (!CheckRunningInMainThread("HistoryInsert"))
		return;

	CallBack2(HISTORY_INSERT, (void*)dataPtr, XOP_CALLBACK_INT(dataLen));
}

/*	HistoryDelete()

	Deletes the currently selected text in the history area.
	
	Except in very rare cases you should not modify the history, except to append to it.
	
	Thread Safety: HistoryDelete is not thread-safe.
*/
void
HistoryDelete(void)
{
	if (!CheckRunningInMainThread("HistoryDelete"))
		return;

	CallBack0(HISTORY_DELETE);
}

/*	HistoryLines()

	Returns the number of lines of text in the history area.
	
	Thread Safety: HistoryLines is not thread-safe.
*/
int
HistoryLines(void)
{
	if (!CheckRunningInMainThread("HistoryLines"))
		return 0;

	if (igorVersion < 600)
		return 0;
	
	return (int)CallBack0(HISTORY_LINES);
}

/*	HistoryGetSelLocs()

	Sets *startLocPtr and *endLocPtr to describe the selected text in the history area.

	Returns 0 if OK or an Igor error code.
	
	Thread Safety: HistoryGetSelLocs is not thread-safe.
*/
int
HistoryGetSelLocs(TULocPtr startLocPtr, TULocPtr endLocPtr)
{
	if (!CheckRunningInMainThread("HistoryGetSelLocs"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack2(HISTORY_GETSELLOCS, startLocPtr, endLocPtr);
}

/*	HistorySetSelLocs()

	Sets the selection in the history area.

	If startLocPtr is NULL, the start location is taken to be the start of history area.

	If endLocPtr is NULL, the end location is taken to be the end of history area.
	
	If flags is 1, displays the selection if it is out of view.
	Other bits in flags must be set to 0 as they may be used for other purposes in the future.

	Returns 0 if OK or an Igor error code.
	
	Returns an error if the start or end locations are out of bounds or if the start location is
	after the end location.
	
	Thread Safety: HistorySetSelLocs is not thread-safe.
*/
int
HistorySetSelLocs(TULocPtr startLocPtr, TULocPtr endLocPtr, int flags)
{
	if (!CheckRunningInMainThread("HistorySetSelLocs"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack3(HISTORY_SETSELLOCS, startLocPtr, endLocPtr, XOP_CALLBACK_INT(flags));
}

/*	HistoryFetchParagraphText()

	Like TUFetchParagraphText but it acts on the history area. See TUFetchParagraphText documentation for details.
	
	To get the length of the paragraph text without actually getting the text, pass NULL for textPtrPtr.

	I textPtrPtr is not NULL and *textPtrPtr is not NULL then you must dispose *textPtrPtr using
	WMDisposePtr when you no longer need it.
	
	Thread Safety: HistoryFetchParagraphText is not thread-safe.
*/
int
HistoryFetchParagraphText(int paragraph,  Ptr* textPtrPtr, int* lengthPtr)
{
	if (textPtrPtr != NULL)
		*textPtrPtr = NULL;

	if (!CheckRunningInMainThread("HistoryFetchParagraphText"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack3(HISTORY_FETCHPARAGRAPHTEXT, XOP_CALLBACK_INT(paragraph), textPtrPtr, lengthPtr);
}

/*	HistoryFetchText(startLocPtr, endLocPtr, textHPtr)

	Returns the history area text from the specified start location to the specified end location.

	If startLocPtr is NULL, the start location is taken to be the start of history area.

	If endLocPtr is NULL, the end location is taken to be the end of history area.
	
	On return, if there is an error, *textHPtr will be NULL. If there is no error, *textHPtr
	will point to a handle containing the text. *textHPtr is not null-terminated. *textHPtr
	belongs to you so dispose it using WMDisposeHandle when you are finished with it.
	
	Thread Safety: HistoryFetchText is not thread-safe.
*/
int
HistoryFetchText(TULocPtr startLocPtr, TULocPtr endLocPtr, Handle* textHPtr)
{
	*textHPtr = NULL;
	
	if (!CheckRunningInMainThread("HistoryFetchText"))
		return NOT_IN_THREADSAFE;

	return (int)CallBack3(HISTORY_FETCHTEXT, startLocPtr, endLocPtr, textHPtr);
}

