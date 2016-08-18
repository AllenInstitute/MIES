/*	For XOPs that add containers to Igor.
	A container is an area of a window that contains user interface elements and/or drawn content.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	CreateXOPContainer(windowRef, parentContainer, units, coords, frameGuides, proposedName, baseName, options, xopContainerPtr)

	Creates a container for window content.
	
	windowRef references the window in which the container is to be created.
	If parentContainer is not NULL, meaning that you are creating a subwindow,
	then windowRef can be NULL.
	
	parentContainer specifies the container in which the new container is to be created.
	If parentContainer is NULL then the new container is created as the top-level
	container of the window. This is valid only if the window does not already have
	a top-level container which will be the case after you call CreateXOPWindow and before
	you create a container within that window.
	
	units specifies the units of the values in coords on input as follows:
		 0: Points
		 1: Inches
		 2: Centimeters
	
	coords specifies the coordinates of the new container relative to its parent
	for subwindows. It does not apply to the top-level container and is ignored
	and can be NULL if parentContainer is NULL.
	
	If parentContainer is not NULL, meaning you are creating a subwindow:
		coords[0] is the location of the left edge of the subwindow.
		coords[1] is the location of the top edge of the subwindow.
		coords[2] is the location of the right edge of the subwindow.
		coords[3] is the location of the bottom edge of the subwindow.
	
	If units is 0 and the values in coords are in the range 0.0 to 1.0, the coordinates
	are taken to be relative to the parent container where 0.0 represents the left and top
	edges and 1.0 represents the right and bottom edges.
	
	frameGuides is an array of four frame guide names as specified by the /FG flag
	of an operation that creates subwindows such as Display or NewPanel. Frame guides
	apply to subwindows only, not to top-level containers. When creating a top-level
	container (parentContainer is NULL), you can pass NULL for the frameGuides parameter.
	When creating a subwindow, if /FG was not specified then each of the four names should be empty ("").
	
	proposedName is either the name for the new container or "". If proposedName
	is "" Igor generates a name based on baseName. Otherwise it generates a name
	based on proposedName. The proposed name must be valid as an Igor subwindow name:
		1.	It must start with a letter and contain only letters, digits and
			the underscore character
		2.	It must be unique within the parent container.
	In the event of a name conflict Igor will generate a unique name based on proposedName.
	
	baseName is used if proposedName is "". In this case Igor generates a name consisting
	of the contents of baseName followed by a number. For example, if baseName is "XOP",
	Igor will generate a unique name like XOP0, XOP1, and so on. The rules for baseName
	are the same as for proposedName.
	
	options is a set of bitwise flags defined by the CreateXOPContainerOptionType enum:
		kCreateXOPContainerNoOptions		All options off
		kCreateXOPContainerHidden			Create initially hidden subwindow	
	
	The pointer to the new container is returned via *xopContainerPtr.
	In the event of an error this will be NULL.
	
	The function result is 0 if OK or a non-zero error code.	

	CreateXOPContainer requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: CreateXOPContainer is not thread-safe.
*/
int
CreateXOPContainer(IgorWindowRef windowRef, IgorContainerRef parentContainer,
									int units, const double coords[4],
									const char frameGuides[4][MAX_OBJ_NAME+1],
									const char* proposedName, const char* baseName, int options,
									IgorContainerRef* xopContainerPtr)
{
	CreateXOPContainerParams params;
	int result;
	
	if (!CheckRunningInMainThread("CreateXOPContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
		
	MemClear(&params, sizeof(params));
	params.windowRef = windowRef;				// Can be NULL if parentContainer is not NULL
	params.parentContainer = parentContainer;
	params.units = units;
	if (coords != NULL)
		memcpy(params.coords, coords, sizeof(params.coords));
	if (frameGuides != NULL)
		memcpy(params.frameGuides, frameGuides, sizeof(params.frameGuides));
	params.proposedName = proposedName;
	params.baseName = baseName;
	params.options = options;	

	result = (int)CallBack2(CREATE_XOP_CONTAINER, &params, xopContainerPtr);
	return result;
}

/*	KillXOPContainer(xopContainer)

	Removes the specified container from its window and kills it.

	xopContainer must be a pointer to an container created by your XOP.
	Otherwise the function returns does nothing and returns an error. 
	
	The function result is 0 if OK or a non-zero error code.	

	The killing of an XOP container can be triggered by:
		Right-clicking it in layout mode and choosing Delete
		Selecting it in layout mode and choosing Delete
		A KillWindow command targeted at a subwindow
		The killing of the parent container
		The killing of the parent window
		The XOP itself calling the KillXOPContainer callback
	
	Here is the sequence of events that happens when an XOP container is killed:
		Igor kills the container which recursively kills all sub-containers from the bottom up
			Igor sends kXOPContainerMessageContainerBeingKilled message to the XOP for each container
				The XOP deletes any container-related objects it created
			
	When an XOP window is killed, as of this writing Igor sends the kXOPContainerMessageContainerBeingKilled
	message after sending the kXOPWindowMessageWindowBeingKilled message. Consequently, by the time the
	XOP receives the kXOPContainerMessageContainerBeingKilled, the window is no longer valid and
	GetIgorWindowInfo will return an error for the window being killed.
		
	See also KillXOPWindow.

	KillXOPContainer requires Igor Pro 7 or later and does nothing if running with an older version.
	
	Thread Safety: KillXOPContainer is not thread-safe.
*/
int
KillXOPContainer(IgorContainerRef xopContainer)
{
	int result;
	
	if (!CheckRunningInMainThread("KillXOPContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	result = (int)CallBack1(KILL_XOP_CONTAINER, xopContainer);
	return result;
}

/*	GetActiveIgorContainer(windowRef, containerPtr)

	Returns via containerPtr a pointer to the active container in the window specified by windowRef.
	
	If windowRef is NULL, it returns a pointer to the active container in the active window.
	
	There may be no active container in which case it returns NULL.

	It also returns NULL the event of an error.
	
	The function result is 0 if OK or a non-zero error code.	

	GetActiveIgorContainer requires Igor Pro 7 or later. It returns
	NULL if running with an older version.
	
	Thread Safety: GetActiveIgorContainer is not thread-safe.
*/
int
GetActiveIgorContainer(IgorWindowRef windowRef, IgorContainerRef* containerPtr)
{
	int result;
	
	*containerPtr = 0;

	if (!CheckRunningInMainThread("GetActiveIgorContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack2(GET_ACTIVE_IGOR_CONTAINER, windowRef, containerPtr);
	return result;
}

/*	ActivateXOPContainer(container)

	Your XOP must call ActivateXOPContainer to inform Igor that an event has happened that
	requires your XOP container to be made the active container. You must call this,
	for example, on a click in the XOP NSView or HWND.
	
	This is necessary because clicks in XOP containers are handled in the XOP and Igor
	does not see them. On Macintosh clicks are consumed by the XOP mouseDown and mouseDown
	methods. On Windows they are consumed when the XOP window proc handles WM_LBUTTONDOWN
	and WM_RBUTTONDOWN messages from Windows.
	
	You can call this on any click in the XOP container. If your container is not already
	the active container, Igor makes it the active container and sends you the
	kXOPContainerMessageActivate message.

	ActivateXOPContainer requires Igor Pro 7 or later. It does nothing if running
	with an older version.
	
	Thread Safety: ActivateXOPContainer is not thread-safe.
*/
void
ActivateXOPContainer(IgorContainerRef xopContainer)
{
	if (!CheckRunningInMainThread("ActivateXOPContainer"))
		return;

	if (igorVersion < 700)
		return;

	CallBack1(SET_ACTIVE_IGOR_CONTAINER, xopContainer);
}

/*	GetNamedIgorContainer(path, mask, containerPtr)

	Returns via containerPtr a pointer to the container specified by path.
	path is a subwindow path like "Panel0", "Panel0#P0", "#" or "#P0". Paths
	that start with "#" are relative to the currently active subwindow.
	
	If path does not name a valid container then the function returns NULL.
	It also returns NULL the event of an error.
	
	mask limits the search to the specified container types (e.g., GRAF_MASK).
	To search for any container type use ALL_MASK.
	
	The function result is 0 if OK or a non-zero error code.	

	GetNamedIgorContainer requires Igor Pro 7 or later. It returns
	NULL if running with an older version.
	
	Thread Safety: GetNamedIgorContainer is not thread-safe.
*/
int
GetNamedIgorContainer(const char* path, int mask, IgorContainerRef* containerPtr)
{
	int result;
	
	*containerPtr = 0;

	if (!CheckRunningInMainThread("GetNamedIgorContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack3(GET_NAMED_IGOR_CONTAINER, (void*)path, XOP_CALLBACK_INT(mask), containerPtr);
	return result;
}

/*	GetParentIgorContainer(container, containerPtr)

	Returns via containerPtr a pointer to the parent of container.
	The parent may itself be a child of another container.
	If container is a top-level container it returns NULL.
	It also returns NULL the event of an error.
	
	The function result is 0 if OK or a non-zero error code.	

	GetParentIgorContainer requires Igor Pro 7 or later. It returns NULL if running
	with an older version.
	
	Thread Safety: GetParentIgorContainer is not thread-safe.
*/
int
GetParentIgorContainer(IgorContainerRef container, IgorContainerRef* containerPtr)
{
	int result;
	
	*containerPtr = 0;

	if (!CheckRunningInMainThread("GetParentIgorContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	result = (int)CallBack2(GET_PARENT_IGOR_CONTAINER, container, containerPtr);
	return result;
}

/*	GetChildIgorContainer(container, index, containerPtr)

	Returns via containerPtr a pointer to the specified child of container.
	index is a zero-based child index.
	
	If container has no children or index is less than zero or greater than the index
	of the last child the function returns NULL. It also returns NULL the event of an error.
	
	The function result is 0 if OK or a non-zero error code.	

	GetChildIgorContainer requires Igor Pro 7 or later. It returns
	NULL if running with an older version.
	
	Thread Safety: GetChildIgorContainer is not thread-safe.
*/
int
GetChildIgorContainer(IgorContainerRef container, int index, IgorContainerRef* containerPtr)
{
	int result;
	
	*containerPtr = 0;

	if (!CheckRunningInMainThread("GetChildIgorContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	result = (int)CallBack3(GET_CHILD_IGOR_CONTAINER, container, XOP_CALLBACK_INT(index), containerPtr);
	return result;
}

/*	GetIndexedXOPContainer(windowRef, index, xopContainerPtr)

	Returns via xopContainerPtr a pointer to the specified container.

	Only containers created by your XOP are searched.
	
	If windowRef is NULL, containers from all windows are searched. Otherwise only containers
	from the specified window are searched.

	index is a zero-based index.
	
	The containers are searched in creation order.
	
	If there is no container matching the parameters the function returns NULL.
	
	The function result is 0 if OK or a non-zero error code.	

	GetIndexedXOPContainer requires Igor Pro 7 or later. It returns
	NULL if running with an older version.
	
	Thread Safety: GetIndexedXOPContainer is not thread-safe.
*/
int
GetIndexedXOPContainer(IgorWindowRef windowRef, int index, IgorContainerRef* xopContainerPtr)
{
	int result;
	
	*xopContainerPtr = NULL;

	if (!CheckRunningInMainThread("GetIndexedXOPContainer"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	result = (int)CallBack3(GET_INDEXED_XOP_CONTAINER, windowRef, XOP_CALLBACK_INT(index), xopContainerPtr);
	return result;
}

/*	GetIgorContainerPath(container, ancestor, path)

	Returns via path the subwindow path to the specified container.
	
	If ancestor is NULL it returns a full path to the container (e.g., "Panel0#G0").
	
	If container is the top-level container of a window, the full path is
	just the window name (e.g., "Panel0") which is, by definition equal to
	the container name.
	
	If ancestor is not NULL and is an ancestor of the container it returns
	a partial path (e.g., "#G0") relative to ancestor.
	
	If ancestor is identical to container then the function returns just the name
	of the container (e.g., "G0").
	
	The function result is 0 if OK or a non-zero error code.	

	GetIgorContainerPath requires Igor Pro 7 or later. It sets path to ""
	and returns an error if running with an older version.
	
	Thread Safety: GetIgorContainerPath is not thread-safe.
*/
int
GetIgorContainerPath(IgorContainerRef container, IgorContainerRef ancestor, char path[MAX_LONG_NAME+1])
{
	int result;
	
	*path = 0;

	if (!CheckRunningInMainThread("GetIgorContainerPath"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;
	
	result = (int)CallBack3(GET_IGOR_CONTAINER_PATH, container, ancestor, path);
	return result;
}

/*	GetIgorContainerInfo(container, which, infoPtr)

	Returns via infoPtr a value associated with the specified container.
	The type of *infoPtr depends on the which parameter.
	In the event of an error, *infoPtr is cleared (e.g., set to NULL, 0 depending on which).
	
	For the items marked with * below, container must be a pointer to an IgorContainer
	created by your XOP. Otherwise the function returns NULL. 
	
	which is one of the following:
		kIgorContainerIgorWindow:				Read-only. Returns IgorWindowRef.
	*	kXOPContainerNSView:					Read-only. Returns NSView*. Valid on Macintosh only.
	*	kXOPContainerHWND:						Read-only. Returns HWND. Valid on Windows only.
	*	kXOPContainerQWidget:					Read-only. Returns QWidget*. For wizards only, experimental.
	*	kXOPContainerXOPPointer:				Read/write. *infoPtr is a pointer to memory allocated by the XOP which defaults to NULL.
	*	kXOPContainerBoundsInPixels:			Read-only. Returns bounds via Rect.
	*	kXOPContainerHiddenState:				Read-only. Returns hidden state via int.
	*	kXOPContainerIsVisible:					Read-only, returns visibility status via int.
	*	kXOPContainerRecreationPositionFlags:	Read-only. Returns recreation text via char[256].
	*	kXOPContainerRecreationSetWindow:		Read-only. Returns SetWindow recreation text via Handle.
	
	"XOPPointer" refers to a pointer that you previously set via SetIgorContainerInfo.
	
	The function result is 0 if the parameters are valid or an Igor error code if they not valid.

	GetIgorContainerInfo requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: GetIgorContainerInfo is not thread-safe.
*/
int
GetIgorContainerInfo(IgorContainerRef container, IgorContainerInfoType which, void** infoPtr)
{
	int result;

	/*	Clear the output because the caller may not check the return error code but instead
		may rely on *infoPtr being cleared. The size of *infoPtr depends on which.
	*/
	switch(which) {
		case kIgorContainerIgorWindow:
			*infoPtr = NULL;							// Output is IgorWindowRef
			break;
		case kXOPContainerNSView:
			*infoPtr = NULL;							// Output is NSView*
			break;
		case kXOPContainerHWND:
			*infoPtr = NULL;							// Output is HWND
			break;
		case kXOPContainerQWidget:
			*infoPtr = NULL;							// Output is QWidget*
			break;
		case kXOPContainerXOPPointer:
			*infoPtr = NULL;							// Output is void*
			break;
		case kXOPContainerBoundsInPixels:
			{
				Rect* rp = (Rect*)infoPtr;				// Output is Rect
				rp->left = rp->top = rp->right = rp->bottom = 0;
			}
			break;
		case kXOPContainerHiddenState:
		case kXOPContainerIsVisible:
			{
				int* ip = (int*)infoPtr;				// Output is int
				*ip = 0;
			}
			break;
		case kXOPContainerRecreationPositionFlags:
			{
				char* text = (char*)infoPtr;			// Output is char[256]
				*text = 0;
			}
			break;
		case kXOPContainerRecreationSetWindow:
			*infoPtr = NULL;							// Output is Handle
			break;
		default:
			return XOP_BAD_PARAMETER;
			break;
	}
	
	if (!CheckRunningInMainThread("GetIgorContainerInfo"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack3(GET_IGOR_CONTAINER_INFO, container, XOP_CALLBACK_INT(which), infoPtr);
	return result;
}

/*	SetIgorContainerInfo(container, which, info)

	Sets a value associated with the specified container.
	
	container must be a pointer to an IgorContainer created by your XOP.
	Otherwise the function does nothing. 
	
	which is one of the following:
		kXOPContainerXOPPointer:		Stores a pointer for later retrieval
	
	You can use kXOPContainerXOPPointer to store a pointer to a structure
	or class containing information that you want to associate with the container. You can
	later retrieve that information via GetIgorContainerInfo.
	
	All other values of the IgorContainerInfoType enum refer to read-only values
	that you can not set.
	
	The function result is 0 if the parameters are valid or an Igor error code if they not valid.

	SetIgorContainerInfo requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: SetIgorContainerInfo is not thread-safe.
*/
int
SetIgorContainerInfo(IgorContainerRef container, IgorContainerInfoType which, void* info)
{
	int result;
	
	if (!CheckRunningInMainThread("SetIgorContainerInfo"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack3(SET_IGOR_CONTAINER_INFO, container, XOP_CALLBACK_INT(which), info);
	return result;
}

/*	SendContainerNSEventToIgor(xopContainer, message, nsView, nsEvent)

	SendContainerNSEventToIgor is for Macintosh only. It sends a container-related event
	to Igor to give Igor a chance to handle it.
	
	If SendContainerNSEventToIgor returns 0 you should handle the event in your code.
	If it returns non-zero, Igor has handled the event and you should do nothing.

	SendContainerNSEventToIgor requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: SendContainerNSEventToIgor is not thread-safe.
*/
#ifdef MACIGOR
int
SendContainerNSEventToIgor(IgorContainerRef xopContainer, int message, const void* nsView, const void* nsEvent)
{
	int result;
	
	if (!CheckRunningInMainThread("SendContainerNSEventToIgor"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack4(SEND_CONTAINER_NSEVENT_TO_IGOR, xopContainer, XOP_CALLBACK_INT(message), (void*)nsView, (void*)nsEvent);
	return result;
}
#endif

/*	SendContainerHWNDEventToIgor(xopContainer, message, hwnd, iMsg, wParam, lParam)

	SendContainerHWNDEventToIgor is for Windows only. It sends a container-related event
	to Igor to give Igor a chance to handle it.
	
	If SendContainerHWNDEventToIgor returns 0 you should handle the event in your code.
	If it returns non-zero, Igor has handled the event and you should do nothing.

	SendContainerHWNDEventToIgor requires Igor Pro 7 or later and does nothing
	if running with an older version.
	
	Thread Safety: SendContainerHWNDEventToIgor is not thread-safe.
*/
#ifdef WINIGOR
int
SendContainerHWNDEventToIgor(IgorContainerRef xopContainer, int message, HWND hwnd, UInt32 iMsg, PSInt wParam, PSInt lParam)
{
	int result;
	
	if (!CheckRunningInMainThread("SendContainerHWNDEventToIgor"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack6(SEND_CONTAINER_HWND_EVENT_TO_IGOR, xopContainer, XOP_CALLBACK_INT(message), (void*)hwnd, XOP_CALLBACK_INT(iMsg), (void*)wParam, (void*)lParam);
	return result;
}
#endif

/*	SetXOPContainerMouseCursor(xopContainer, mouseCursorCode)

	Sets the mouse cursor for the specified container.
	
	On Macintosh, Qt traps mouse move events at a low level, before they are sent
	to the XOP NSView, and sets the cursor. Because of this Macintosh XOPs need to
	use callbacks to Igor to set the cursor and platform-dependent techniques will
	not work because Qt interferes. See HandleMouseMoved in WindowXOP1 for an example.
	
	On Windows, mouse move events for XOP containers do not reach Qt so Qt does not
	set the cursor. Special code inside Igor makes SetXOPContainerMouseCursor on
	Windows despite this. Therefore you can use either the platform-independent
	SetXOPContainerMouseCursor or platform-dependent techniques on Windows.
	See XOPWindowProc in WindowXOP1 for an example.
	
	You can also set the mouse cursor by calling one of these functions:
		ArrowCursor, IBeamCursor, WatchCursor, HandCursor
	
	mouseCursorCode is an IgorMouseCursorCode enum as listed in IgorXOP.h. See the
	"Mouse Cursor Control.pxp" example experiment, which ships with Igor7, for a
	list of supported cursors and their corresponding codes.
	
	The function result is 0 if the mouse cursor code is valid or a non-zero error code if it
	is out of bounds.

	SetXOPContainerMouseCursor requires Igor Pro 7 or later and returns an error
	if running with an older version.
	
	Thread Safety: SetXOPContainerMouseCursor is not thread-safe.
*/
int
SetXOPContainerMouseCursor(IgorContainerRef xopContainer, enum IgorMouseCursorCode mouseCursorCode)
{
	int result;
	
	if (!CheckRunningInMainThread("SetXOPContainerMouseCursor"))
		return NOT_IN_THREADSAFE;

	if (igorVersion < 700)
		return IGOR_OBSOLETE;

	result = (int)CallBack2(SET_XOP_CONTAINER_MOUSE_CURSOR, xopContainer, XOP_CALLBACK_INT(mouseCursorCode));
	return result;
}

