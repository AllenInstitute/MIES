/*	Windows in XOPs

	The term "window XOP" is shorthand for an XOP that adds one or more windows
	to Igor. Most XOPs add no windows to Igor and for them the material discussed
	here is irrelevant.
	
	IP6 window XOPs are not compatible with IP7. They must be revised to use the
	IP7 window XOP protocol.
	
	IP7 window XOPs are not compatible with IP6. They require IP7 or later.
	
	An IgorWindowRef is a pointer to an object that represents an Igor window
	whether the window was Igor-created or XOP-created.
	
	When you see "XOP" in the name of a message, callback this means that the
	message or callback applies only to XOP windows. When you see Igor in the name
	it means that the message or callback applies to any Igor window.
	
	When you see "XOP" in the name of a parameter this means that the parameter
	must be an XOP-created window.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	CreateXOPWindow(units, coords, title, options, xopWindowRefPtr)

	CreateXOPWindow creates a new XOP window and returns a reference to it
	via xopWindowRefPtr. The window is initially hidden. Call ShowIgorWindow
	to show it.
	
	units specifies the units of the values in coords on input as follows:
		 0: Points
		 1: Inches
		 2: Centimeters
	
	coords specifies the coordinates of the new window in IGOR coordinates.
	See the discussion under TransformWindowCoordinates for details about IGOR coordinates.
	
	coords is arranged as follows:
		coords[0] is the location of the left edge of the window.
		coords[1] is the location of the top edge of the window.
		coords[2] is the location of the right edge of the window.
		coords[3] is the location of the bottom edge of the window.
	
	title is a C string to use as the window title.

	options is a set of bitwise flags defined by the CreateXOPWindowOptionType enum:
		kCreateXOPWindowNoOptions			All options off
		kCreateXOPWindowAsTargetWindow		Create window as target window	
	
	The function result is 0 if there was no error or a non-zero error code.
	In the event of an error *xopWindowRefPtr is set to NULL.

	CreateXOPWindow requires Igor Pro 7 or later and returns IGOR_OBSOLETE
	if running with an older version.
	
	Thread Safety: CreateXOPWindow is not thread-safe.
*/
int
CreateXOPWindow(int units, const double coords[4], const char* title, int options, IgorWindowRef* xopWindowRefPtr)
{
	int err;
	
	*xopWindowRefPtr = NULL;

	if (!CheckRunningInMainThread("CreateXOPWindow"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	err = (int)CallBack5(CREATE_XOP_WINDOW, XOP_CALLBACK_INT(units), (void*)coords, (void*)title, XOP_CALLBACK_INT(options), xopWindowRefPtr);
	return err;
}

/*	KillXOPWindow(xopWindowRef)

	KillXOPWindow kills an XOP window created by CreateXOPWindow.
	
	The function result is 0 if there was no error or a non-zero error code.

	The killing of an XOP window can be triggered by:
		Clicking the close box
		Choosing Windows->Close
		A DoWindow/K or KillWindow command
		Igor when the current experiment is closed
		The XOP itself calling the KillXOPWindow callback
	
	Here is the sequence of events that happens when an XOP window is killed:
		Igor hides the window
		Igor sends the kXOPWindowMessageWindowBeingKilled message to the XOP
			The XOP deletes any window-related objects it created
		Igor deletes its internal record for the XOP window
			Now GetIgorWindowInfo will return an error for the window being killed
		Igor kills the top-level container which recursively kills all sub-containers from the bottom up
			Igor sends kXOPContainerMessageContainerBeingKilled message to the XOP for each container
				The XOP deletes any container-related objects it created
		
	See also KillXOPContainer.

	KillXOPWindow requires Igor Pro 7 or later and returns IGOR_OBSOLETE
	if running with an older version.
	
	Thread Safety: KillXOPWindow is not thread-safe.
*/
int
KillXOPWindow(IgorWindowRef xopWindowRef)
{
	int err;
	
	if (!CheckRunningInMainThread("KillXOPWindow"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	err = (int)CallBack1(KILL_XOP_WINDOW, xopWindowRef);
	return err;
}

/*	GetIndexedXOPWindow(index)

	GetIndexedXOPWindow returns the IgorWindowRef for the indexth XOP window created
	by your XOP or NULL if there are no more such windows.
	
	The windows are returned in order of creation, not desktop order. Use GetNextXOPWindow
	if you need to access your windows in desktop order.

	GetIndexedXOPWindow requires Igor Pro 7 or later and returns NULL
	if running with an older version.
	
	Thread Safety: GetIndexedXOPWindow is not thread-safe.
*/
IgorWindowRef
GetIndexedXOPWindow(int index)
{
	IgorWindowRef xopWindowRef;
	
	if (!CheckRunningInMainThread("GetIndexedXOPWindow"))
		return NULL;

	if (igorVersion < 700)
		return NULL;
		
	xopWindowRef = (IgorWindowRef)CallBack1(GET_INDEXED_XOP_WINDOW, XOP_CALLBACK_INT(index));
	return xopWindowRef;
}

/*	GetNextXOPWindow(xopWindowRef, visibleOnly)

	GetNextXOPWindow allows you to iterate through your XOP windows in desktop order.
	"Desktop order" refers to the front-to-back stacking order of windows on the desktop.
	It ignores windows not created by your XOP.

	GetNextXOPWindow returns the IgorWindowRef for the next XOP window from your XOP
	after xopWindowRef. If xopWindowRef is NULL, it returns the IgorWindowRef for the
	frontmost XOP window from your XOP.
	
	If it is not NULL, xopWindowRef must reference a window created by your XOP.
	
	If visibleOnly is non-zero, the search is limited to visible windows only.
	Otherwise the search includes all windows, visible and invisible.
	
	GetNextXOPWindow returns NULL if there are no windows matching the criteria.

	GetNextXOPWindow requires Igor Pro 7 or later and returns NULL
	if running with an older version.
	
	Thread Safety: GetNextXOPWindow is not thread-safe.
*/
IgorWindowRef
GetNextXOPWindow(IgorWindowRef xopWindowRef, int visibleOnly)
{
	IgorWindowRef nextXOPWindowRef;
	
	if (!CheckRunningInMainThread("GetNextXOPWindow"))
		return NULL;

	if (igorVersion < 700)
		return NULL;
		
	nextXOPWindowRef = (IgorWindowRef)CallBack2(GET_NEXT_XOP_WINDOW, xopWindowRef, XOP_CALLBACK_INT(visibleOnly));
	return nextXOPWindowRef;
}

/*	GetIgorWindowInfo(windowRef, which, infoPtr)

	GetIgorWindowInfo returns a value associated with the specified window via infoPtr.
	The type of *infoPtr depends on the which parameter.
	In the event of an error, *infoPtr is cleared (e.g., set to NULL, 0 depending on which).
	
	For the items marked with * below, windowRef must be a pointer to a window
	created by your XOP. Otherwise the function returns NULL. 
	
	which is one of the following:
	*	kXOPWindowNSView:					Read-only. Returns NSView*. Valid on Macintosh only.
	*	kXOPWindowHWND:						Read-only. Returns HWND. Valid on Windows only.
	*	kXOPWindowQWidget:					Read-only. Returns QWidget*. For wizards only, experimental.
	*	kXOPWindowXOPPointer:				Read/write. *infoPtr is a pointer to memory allocated by the XOP which defaults to NULL.
		kIgorWindowWinType:					Read-only. Returns winType (XOPWIN or XOPTARGWIN) via int.
		kIgorWindowWinName:					Read-only. Returns window name via char[MAX_OBJ_NAME+1].
		kIgorWindowBoundsInPixels:			Read-only. Returns window bounds in pixels via Rect.
		kIgorWindowHiddenState:				Read-only. Returns hidden state via int.
		kIgorWindowKillMode:				Read/write. Sets/reads kill mode via int. See IgorWindowKillMode enum.
	
	"XOPPointer" refers to a pointer that you previously set via SetXOPWindowInfo.
	
	The kIgorWindowKillMode setting is not valid unless the window has a top-level container.
	Consequently, do not call this after creating an XOP window until you have created the
	window's top-level container.
	
	Once the killing of an XOP window has started, GetIgorWindowInfo returns an error for the
	window being killed. See KillXOPWindow and KillXOPContainer for a discussion of the sequence
	of events.
	
	The function result is 0 if the parameters are valid or an Igor error code if they not valid.

	GetIgorWindowInfo requires Igor Pro 7 or later and returns NULL if running with an older version.
	
	Thread Safety: GetIgorWindowInfo is not thread-safe.
*/
int
GetIgorWindowInfo(IgorWindowRef windowRef, IgorWindowInfoType which, void** infoPtr)
{
	int result;
	
	/*	Clear the output because the caller may not check the return error code but instead
		may rely on *infoPtr being cleared. The size of *infoPtr depends on which.
	*/
	switch(which) {
		case kXOPWindowNSView:
			*infoPtr = NULL;					// Output is NSView*
			break;
		case kXOPWindowHWND:
			*infoPtr = NULL;					// Output is HWND
			break;
		case kXOPWindowQWidget:
			*infoPtr = NULL;					// Output is QWidget*
			break;
		case kXOPWindowXOPPointer:
			*infoPtr = NULL;					// Output is void*
			break;
		case kIgorWindowWinType:
			{
				int* ip = (int*)infoPtr;		// Output is int
				*ip = 0;
			}
			break;
		case kIgorWindowWinName:
			{
				char* text = (char*)infoPtr;	// Output is char[MAX_OBJ_NAME+1]
				*text = 0;
			}
			break;
		case kIgorWindowBoundsInPixels:
			{
				Rect* rp = (Rect*)infoPtr;		// Output is Rect
				rp->left = rp->top = rp->right = rp->bottom = 0;
			}
			break;
		case kIgorWindowHiddenState:
			{
				int* ip = (int*)infoPtr;		// Output is int
				*ip = 0;
			}
			break;
		case kIgorWindowKillMode:
			{
				int* ip = (int*)infoPtr;		// Output is int
				*ip = 0;
			}
			break;
		default:
			return XOP_BAD_PARAMETER;
			break;
	}
	
	if (!CheckRunningInMainThread("GetIgorWindowInfo"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
		
	result = (int)CallBack3(GET_IGOR_WINDOW_INFO, windowRef, XOP_CALLBACK_INT(which), infoPtr);
	return result;
}

/*	SetXOPWindowInfo(xopWindowRef, which, info)

	SetXOPWindowInfo sets a value associated with the specified window.
	
	window must be a pointer to a window created by your XOP.
	Otherwise the function does nothing. 
	
	which is one of the following:
		kXOPWindowXOPPointer:				Stores a pointer for later retrieval
		kIgorWindowKillMode:				Read/write, via int*; See IgorWindowKillMode enum
	
	You can use kXOPWindowXOPPointer to store a pointer to a structure
	or class containing information that you want to associate with the window. You can
	later retrieve that information via GetIgorWindowInfo.
	
	The kIgorWindowKillMode setting is not valid unless the window has a top-level container.
	Consequently, do not call this after creating an XOP window until you have created the
	window's top-level container.
	
	All other values of the IgorWindowInfoType enum refer to read-only values
	that you can not set.
	
	The function result is 0 if the parameters are valid or an Igor error code if they not valid.

	SetXOPWindowInfo requires Igor Pro 7 or later and returns NULL
	if running with an older version.
	
	Thread Safety: SetXOPWindowInfo is not thread-safe.
*/
int
SetXOPWindowInfo(IgorWindowRef xopWindowRef, IgorWindowInfoType which, void* info)
{
	int result;

	if (!CheckRunningInMainThread("SetXOPWindowInfo"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
		
	result = (int)CallBack3(SET_XOP_WINDOW_INFO, xopWindowRef, XOP_CALLBACK_INT(which), info);
	return result;
}

/*	GetActiveIgorWindow()
	
	Returns an IgorWindowRef for the active window or NULL.
	
	The returned value could be NULL if no windows are no visible.
	
	The returned IgorWindowRef may reference an XOP-created window or an Igor-created window.
	
	GetActiveIgorWindow requires Igor Pro 7 or later and returns NULL if running with an older version.
	
	Thread Safety: GetActiveIgorWindow is not thread-safe.
*/
IgorWindowRef
GetActiveIgorWindow(void)
{
	IgorWindowRef windowRef;
	
	if (!CheckRunningInMainThread("GetActiveIgorWindow"))
		return NULL;

	if (igorVersion < 700)
		return NULL;
		
	// This is implemented as a callback in Igor7. Previously it was implemented in this file.
	windowRef = (IgorWindowRef)CallBack0(GET_ACTIVE_IGOR_WINDOW);
	return windowRef;
}

/*	GetNamedIgorWindow(name)
	
	Returns an IgorWindowRef for the named window or NULL.
	
	The returned value could be NULL if no windows are no visible.
	
	The returned IgorWindowRef may reference an XOP-created window or an Igor-created window.
	
	GetNamedIgorWindow requires Igor Pro 7 or later and returns NULL if running with an older version.
	
	Thread Safety: GetNamedIgorWindow is not thread-safe.
*/
IgorWindowRef
GetNamedIgorWindow(const char* name)
{
	IgorWindowRef windowRef;
	
	if (!CheckRunningInMainThread("GetNamedIgorWindow"))
		return NULL;

	if (igorVersion < 700)
		return NULL;
		
	windowRef = (IgorWindowRef)CallBack1(GET_NAMED_IGOR_WINDOW, (void*)name);
	return windowRef;
}

/*	IsIgorWindowActive(windowRef)
	
	IsIgorWindowActive requires Igor Pro 7 or later and returns 0 if running with an older version.

	Thread Safety: IsIgorWindowActive is not thread-safe.
*/
int
IsIgorWindowActive(IgorWindowRef windowRef)
{
	int result;
	
	if (!CheckRunningInMainThread("IsIgorWindowActive"))
		return 0;

	if (igorVersion < 700)
		return 0;
	
	// This is implemented as a callback in Igor7. Previously it was implemented in this file.
	result = (int)CallBack1(IS_IGOR_WINDOW_ACTIVE, windowRef);
	return result;
}

/*	IsIgorWindowVisible(windowRef)
	
	IsIgorWindowVisible returns 1 if the window is visible, 0 if it is hidden.
	
	IsIgorWindowVisible requires Igor Pro 7 or later and returns 0 if running with an older version.

	Thread Safety: IsIgorWindowVisible is not thread-safe.
*/
int
IsIgorWindowVisible(IgorWindowRef windowRef)
{
	int result;
	
	if (!CheckRunningInMainThread("IsIgorWindowVisible"))
		return 0;

	if (igorVersion < 700)
		return 0;
	
	result = (int)CallBack1(IS_IGOR_WINDOW_VISIBLE, windowRef);
	return result;
}

/*	ShowIgorWindow(windowRef)

	Shows the window without activating it. Call this in response to the XOP_SHOW_WINDOW
	message from Igor.
	
	ShowIgorWindow requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: ShowIgorWindow is not thread-safe.
*/
void
ShowIgorWindow(IgorWindowRef windowRef)
{
	if (!CheckRunningInMainThread("ShowIgorWindow"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack1(SHOW_IGOR_WINDOW, windowRef);
}

/*	HideIgorWindow(windowRef)

	Hides the window without sending it to the bottom of the desktop. Call this in response
	to the XOP_SHOW_WINDOW message from Igor.

	HideIgorWindow requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: HideIgorWindow is not thread-safe.
*/
void
HideIgorWindow(IgorWindowRef windowRef)
{
	if (!CheckRunningInMainThread("HideIgorWindow"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack1(HIDE_IGOR_WINDOW, windowRef);
}

/*	ShowAndActivateIgorWindow(windowRef)

	ShowAndActivateIgorWindow requires Igor Pro 7 or later and does nothing if running with an older version.

	Thread Safety: ShowAndActivateIgorWindow is not thread-safe.
*/
void
ShowAndActivateIgorWindow(IgorWindowRef windowRef)
{
	if (!CheckRunningInMainThread("ShowAndActivateIgorWindow"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack1(SHOW_AND_ACTIVATE_IGOR_WINDOW, windowRef);
}

/*	HideAndDeactivateIgorWindow(windowRef)

	HideAndDeactivateIgorWindow requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: HideAndDeactivateIgorWindow is not thread-safe.
*/
void
HideAndDeactivateIgorWindow(IgorWindowRef windowRef)
{
	if (!CheckRunningInMainThread("HideAndDeactivateIgorWindow"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack1(HIDE_AND_DEACTIVATE_IGOR_WINDOW, windowRef);
}

/*	GetIgorWindowTitle(windowRef, title)

	This routine was added in XOP Toolkit 7.0 but works with all supported
	versions of Igor.
	
	title must be able to hold 255 bytes plus the null terminator.

	GetIgorWindowTitle requires Igor Pro 7 or later. When running with an older version
	it sets title to "".
	
	Thread Safety: GetIgorWindowTitle is not thread-safe.
*/
void
GetIgorWindowTitle(IgorWindowRef windowRef, char title[256])
{
	*title = 0;
	
	if (!CheckRunningInMainThread("GetIgorWindowTitle"))
		return;

	if (igorVersion < 700)
		return;

	CallBack2(GET_IGOR_WINDOW_TITLE, windowRef, title);
}

/*	SetIgorWindowTitle(windowRef,  title)

	SetIgorWindowTitle requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: SetIgorWindowTitle is not thread-safe.
*/
void
SetIgorWindowTitle(IgorWindowRef windowRef, const char* title)
{
	if (!CheckRunningInMainThread("SetIgorWindowTitle"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack2(SET_IGOR_WINDOW_TITLE, windowRef, (char*)title);
}

/*	GetIgorWindowPositionAndState(theWindow, r, winStatePtr)
	
	Returns the XOP window's position on the screen in pixels and its state.
	Used with SetIgorWindowPositionAndState to save and restore a window's position
	and state.
	
	Use this routine when you need to store a window position in a platform-dependent
	way, for example, in a preference file. Use GetXOPWindowIgorPositionAndState
	to store a window position in a platform-independent way, for example, in a
	/W=(left,top,right,bottom) flag.
	
	MACINTOSH
	
		r is in units of screen pixels. It specifies the location of the window's content
		region in global coordinates.
		
		winStatePtr is set as follows:
			Bit 0:		Set if the window is visible, cleared if it is hidden
			All other bits are set to 0.
			
	WINDOWS
		r is set to the position of the entire window in normal state in screen pixels
		relative to the top/left corner of the Igor MDI client window.
	
		winStatePtr is set as follows:
			Bit 0:		Set if the window is visible, cleared if it is hidden
			Bit 1:		Set if the window is minimized, cleared if it is not minimized

	GetIgorWindowPositionAndState requires Igor Pro 7 or later and clears the
	output parameters if running with an older version.
	
	Thread Safety: GetIgorWindowPositionAndState is not thread-safe.
*/
void
GetIgorWindowPositionAndState(IgorWindowRef windowRef, Rect* r, int* winStatePtr)
{
	if (!CheckRunningInMainThread("GetIgorWindowPositionAndState")) {
		MemClear(r, sizeof(Rect));
		*winStatePtr = 0;
		return;
	}

	if (igorVersion < 700) {
		MemClear(r, sizeof(Rect));
		*winStatePtr = 0;
		return;
	}
	
	CallBack3(GET_IGOR_WINDOW_POSITION_AND_STATE, windowRef, r, winStatePtr);
}

/*	SetIgorWindowPositionAndState(theWindow, r, winState)
	
	Moves the XOP window to the position indicated by r and sets its state.
	Used with GetIgorWindowPositionAndState to save and restore a window's position
	and state.
	
	Use this routine when you need to restore a window position in a platform-dependent
	way, for example, in a preference file. Use SetIgorWindowIgorPositionAndState
	to restore a window position in a platform-independent way, for example, in a
	/W=(left,top,right,bottom) flag.
	
	r is in units of screen pixels. It specifies the location of the window's content
	region in global coordinates. If you pass 0,0,0,0 in r then the position of the window
	is left unchanged.
	
	winState is defined as follows:
	
		Bit 0:	0: Don't show the window
				1: Show the window
		
		Bit 1:	0: Don't hide the window
				1: Hide the window
			
		Bit 2:	0: Don't minimize the window
				1: Minimize the window
				
		Bit 3:	0: Don't maximize the window
				1: Maximize the window
					
		Bit 4:	0: Don't put the window in full screen mode
				1: Put the window in full screen mode
				Full screen is not supported on Macintosh
				Full screen does not work on Windows (Qt4 and Qt5 bug)
			
		Bit 5:	0: Don't normalize the window
				1: Normalize the window
				Normalizing a maximized window does not work on Windows (Qt4 and Qt5 bug)
				
		Bit 6:	0: coords are clipped to keep the window on screen
				1: coords are not clipped
				(Setting this bit does not work on Macintosh because, apparently, Cocoa does its own clipping.)
				 
		If you set multiple bits that are contradictory the result is undefined. For example,
		on some systems you can not normalize the window and hide it as normalization shows
		a hidden window.

	SetIgorWindowPositionAndState requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: SetIgorWindowPositionAndState is not thread-safe.
*/
void
SetIgorWindowPositionAndState(IgorWindowRef windowRef, const Rect* r, int winState)
{
	if (!CheckRunningInMainThread("SetIgorWindowPositionAndState"))
		return;

	if (igorVersion < 700)
		return;
	
	CallBack3(SET_IGOR_WINDOW_POSITION_AND_STATE, windowRef, (void*)r, XOP_CALLBACK_INT(winState));
}

/*	TransformWindowCoordinates(mode, coords)

	Transforms window coordinates from screen pixels into Igor coordinates or
	from Igor coordinates into screen pixels. This routine is intended for use
	in command line operations that set a window position, for example, for
	an operation that supports a /W=(left,top,right,bottom) flag. We want
	a given command containing a /W flag to produce approximately the same result
	on Macintosh and on Windows. This is complicated because of differences in
	the way each platform represents the position of windows.

	Igor coordinates are a special kind of coordinates that were designed to solve
	this problem. Igor coordinates are in units of points, not pixels. On Macintosh,
	Igor coordinates are the same as global coordinates - points relative to the top/left
	corner of the main screen. On Windows, Igor coordinates are points relative to a spot
	20 points above the top/left corner of the MDI client area. As a result of this
	definition, the vertical coordinate 20 corresponds to the point just below the main
	menu bar on both platforms.

	The use of Igor coordinates in commands means that you can transport files and
	commands from one platform to the other and get reasonable results. However,
	the results may not be exactly what you expect. The reason for this is that
	Igor positions the "content" portion of a window. The content portion is the
	portion of the window exclusive of the frame and title bar (border and caption
	in Windows terminology). Because the size of window borders and captions is
	variable on Windows, when you open a Macintosh experiment on Windows or vice versa,
	the window positions might be slightly different from what you would expect. 
	
	We keep coordinates in floating point because, to accurately reposition a
	window, we need to use fractional points in /W=(left,top,right,bottom) flags.
	
	mode is
		0:		Transform from screen pixels into Igor coordinates.
		1:		Transform from Igor coordinates into screen pixels.
		
	For TransformWindowCoordinates, screen pixels are in global coordinates on
	Macintosh (relative to the top/left corner of the main screen) and are in
	MDI-client coordinates (relative to the top/left corner of the MDI client
	window, not the MDI frame) on Windows.  
		
	coords is an array of window coordinates. It is both an input and an output.
	The coordinates specify the location of the window's content area only. That
	is, it excludes the title bar and the frame.
	
	coords[0] is the location of the left edge of the window content area.
	coords[1] is the location of the top edge of the window content area.
	coords[2] is the location of the right edge of the window content area.
	coords[3] is the location of the bottom edge of the window content area.
	
	On Macintosh, screen coordinates and Igor coordinates are identical. Thus, this
	routine is a NOP on Macintosh.

	TransformWindowCoordinates requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: TransformWindowCoordinates is not thread-safe.
*/
void
TransformWindowCoordinates(int mode, double coords[4])
{
	if (!CheckRunningInMainThread("TransformWindowCoordinates"))
		return;

	if (igorVersion < 700)
		return;

	CallBack2(TRANSFORM_IGOR_WINDOW_COORDINATES, XOP_CALLBACK_INT(mode), coords);
}

/*	GetIgorWindowIgorPositionAndState(theWindow, coords, winStatePtr)
	
	Returns the XOP window's position on the screen in Igor coordinates and its state.
	Used with SetIgorWindowIgorPositionAndState to save and restore a window's position
	and state.
	
	Use this routine when you need to store a window position in a platform-independent
	way, for example, in a /W=(left,top,right,bottom) flag. Use GetIgorWindowPositionAndState
	to store a window position in a platform-dependent way, for example, in a preference file.
	
	See XOPTransformWindowCoordinates for a discussion of Igor coordinates. On
	both Macintosh and Windows, the returned coordinates specify the location
	of the window's content region, not the outside edges of the window. On Windows,
	the returned coordinates specify the the location of the window in its normal state
	even if the window is minmized or maximized.
	
	winStatePtr is set as follows:
		Bit 0:		Set if the window is visible, cleared if it is hidden
		Bit 1:		Set if the window is minimized, cleared if it is not minimized
		Bit 2:		Set if the window is maximized, cleared if it is not maximized
		Bit 3:		Set if the window is in full screen mode, cleared if it is not in full screen mode
		All other bits are set to 0.

	GetIgorWindowIgorPositionAndState requires Igor Pro 7 or later and clears the
	output parameters if running with an older version.
	
	Thread Safety: GetIgorWindowIgorPositionAndState is not thread-safe.
*/
void
GetIgorWindowIgorPositionAndState(IgorWindowRef windowRef, double coords[4], int* winStatePtr)
{
	if (!CheckRunningInMainThread("GetIgorWindowIgorPositionAndState")) {
		MemClear(coords, 4*sizeof(double));
		*winStatePtr = 0;
		return;
	}

	if (igorVersion < 700) {
		MemClear(coords, 4*sizeof(double));
		*winStatePtr = 0;
		return;
	}

	CallBack3(GET_IGOR_WINDOW_IGOR_POSITION_AND_STATE, windowRef, coords, winStatePtr);
}

/*	SetIgorWindowIgorPositionAndState(igorWindowRef, coords, winState)
	
	Moves the XOP window to the position indicated by coords and sets its state.
	Used with GetIgorWindowIgorPositionAndState to save and restore a window's position
	and state.
	
	Use this routine when you need to restore a window position in a platform-independent
	way, for example, in a /W=(left,top,right,bottom) flag. Use SetIgorWindowPositionAndState
	to restore a window position in a platform-dependent way, for example, in a preference file.
	
	See XOPTransformWindowCoordinates for a discussion of Igor coordinates. On
	both Macintosh and Windows, the coordinates specify the location of the window's
	content region, not the outside edges of the window. The coordinates specify the
	location of the window in its normal state even if the window is minmized or maximized.
	
	If you pass 0,0,0,0 in coords then the position of the window is left unchanged.

	winState is defined as follows:
	
		Bit 0:	0: Don't show the window
				1: Show the window
		
		Bit 1:	0: Don't hide the window
				1: Hide the window
			
		Bit 2:	0: Don't minimize the window
				1: Minimize the window
				
		Bit 3:	0: Don't maximize the window
				1: Maximize the window
					
		Bit 4:	0: Don't put the window in full screen mode
				1: Put the window in full screen mode
				Full screen is not supported on Macintosh
				Full screen does not work on Windows (Qt4 and Qt5 bug)
			
		Bit 5:	0: Don't normalize the window
				1: Normalize the window
				Normalizing a maximized window does not work on Windows (Qt4 and Qt5 bug)
				
		Bit 6:	0: coords are clipped to keep the window on screen
				1: coords are not clipped
				(Setting this bit does not work on Macintosh because, apparently, Cocoa does its own clipping.)
		
	All other bits are reserved and must be set to 0.

	SetIgorWindowIgorPositionAndState requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: SetIgorWindowIgorPositionAndState is not thread-safe.
*/
void
SetIgorWindowIgorPositionAndState(IgorWindowRef windowRef, double coords[4], int winState)
{
	if (!CheckRunningInMainThread("SetIgorWindowIgorPositionAndState"))
		return;

	if (igorVersion < 700)
		return;

	CallBack3(SET_IGOR_WINDOW_IGOR_POSITION_AND_STATE, windowRef, coords, XOP_CALLBACK_INT(winState));
}

/*	TellIgorWindowStatus(windowRef, status, options)

	This function was removed in XOP Toolkit 7 because the functionality is now handled
	internally by Igor Pro 7.
*/

