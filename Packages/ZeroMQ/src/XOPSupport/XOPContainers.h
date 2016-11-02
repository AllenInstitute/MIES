// For XOPs that add containers to Igor.
// A container is an area of a window that contains user interface elements and/or drawn content.

#ifndef XOP_CONTAINERS_H
#define XOP_CONTAINERS_H

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(2)	// All structures passed to Igor are two-byte aligned.

/*	IgorContainers and XOPContainers

	"Container" is the XOP Toolkit term that corresponds to "subwindow" in Igor terminology.
	"Container" is short for "window content container". It is the object that represents
	what is drawn in all or part of a window.
	
	An IgorContainer is a pointer to an object that represents any kind of Igor window
	content container, whether the container was Igor-created or XOP-created. "IgorContainer"
	means "a reference to a container and I don't care if it is Igor-created or XOP-created".
	
	An XOPContainer is a pointer to an object that represents a container created by an XOP.
	"container" means "a reference to a container that must be XOP-created".
	
	Because inside Igor the XOP container object is a subclass of the Igor container object,
	it is OK to reference an XOP container using IgorContainer.
	
	When you see IgorContainer as a callback parameter, this means that the callback works
	with any kind of Igor container, whether Igor-created or XOP-created.
	
	When you see XOPContainer as a callback parameter, this means that the callback works
	with XOP-created container only.
		
	In the XOP Toolkit both IgorContainer and XOPContainer are typedefed as void*. Consequently
	the distinction between them is not enforced by the compiler. It is merely used to
	increase the expressiveness of the XOP code.
*/

// These are used by window XOPs to distinguish container messages from other messages
#define kXOPContainerMessageFirst 1500
#define kXOPContainerMessageLast 1599
	
enum {
	// General Container Messages
	kXOPContainerMessageStart = 1500,
	kXOPContainerMessageContainerBeingKilled = kXOPContainerMessageStart,
	kXOPContainerMessageWindowActivate,		// Container's window activated or deactivated 
	kXOPContainerMessageActivate,			// Container itself activated or deactivated
	kXOPContainerMessageContainerHidden,	// Container was hidden
	kXOPContainerMessageContainerShown,		// Container was shown
	kXOPContainerMessageResized,			// Container was resized
	kXOPContainerMessageMoved,				// Not yet implemented
	kXOPContainerMessageMouseClick,
	kXOPContainerMessageMouseMove,
	kXOPContainerMessageKeyPressed,
	kXOPContainerMessageUpdateEditMenu,
	kXOPContainerMessageUpdateSlotMenu,
	kXOPContainerMessageDoUpdate,			// Not yet implemented and probably not needed
	kXOPContainerMessageUsingWave,			// Asks container if it is using a wave - Return 0 if no, 1 if yes
	kXOPContainerMessageRenamed,			// The container was renamed
	kXOPContainerMessageRecreationText,		// Asks container for text suitable for recreation macro
	kXOPContainerMessageStyleMacroText,		// Asks container for text suitable for style macro
	kXOPContainerMessageEnd,

	// Edit Menu Container Messages
	kXOPContainerMessageEditMenuStart = 1550,
	kXOPContainerMessageUndo = kXOPContainerMessageEditMenuStart,
	kXOPContainerMessageRedo,
	kXOPContainerMessageCut,
	kXOPContainerMessageCopy,
	kXOPContainerMessagePaste,
	kXOPContainerMessageClear,
	kXOPContainerMessageInsertFile,
	kXOPContainerMessageSelectAll,
	kXOPContainerMessageFind,
	kXOPContainerMessageFindSame,
	kXOPContainerMessageFindSameBackwards,
	kXOPContainerMessageFindSelection,
	kXOPContainerMessageFindSelectionBackwards,
	kXOPContainerMessageUseSelectionForFind,
	kXOPContainerMessageDisplaySelection,
	kXOPContainerMessageReplace,
	kXOPContainerMessageIndentLeft,
	kXOPContainerMessageIndentRight,
	kXOPContainerMessageEditMenuEnd,
};

struct CreateXOPContainerParams				// Used for CreateXOPContainer callback
{
	IgorWindowRef windowRef;
	IgorContainerRef parentContainer;		// Can be NULL
	int units;
	double coords[4];
	char frameGuides[4][MAX_OBJ_NAME+1];
	const char* proposedName;
	const char* baseName;
	int options;	
};
typedef struct CreateXOPContainerParams CreateXOPContainerParams;
typedef CreateXOPContainerParams* CreateXOPContainerParamsPtr;

typedef enum {								// Used with CreateXOPContainer option parameter
	kCreateXOPContainerNoOptions=0,
	kCreateXOPContainerHidden=1,
} CreateXOPContainerOptionType;

typedef enum {		// Used as parameter to GetIgorContainerInfo and SetIgorContainerInfo
	kIgorContainerIgorWindow=1,				// Read-only
	kXOPContainerNSView,					// Read-only, valid on Macintosh only, valid only for XOP-created container
	kXOPContainerHWND,						// Read-only, valid on Windows only, valid only for XOP-created container
	kXOPContainerQWidget,					// Read-only, for wizards only, valid only for XOP-created container
	kXOPContainerXOPPointer,				// Read/write, defaults to NULL
	kXOPContainerBoundsInPixels,			// Read-only, returns bounds via Rect*
	kXOPContainerHiddenState,				// Read-only, returns hidden state via int*
	kXOPContainerIsVisible,					// Read-only, returns visibility status via int*
	kXOPContainerRecreationPositionFlags,	// Read-only, returns recreation text via char*
	kXOPContainerRecreationSetWindow,		// Read-only, returns SetWindow recreation text via Handle*
} IgorContainerInfoType;

#pragma pack()	// Reset structure alignment to default.

#ifdef __cplusplus
}
#endif

#endif	// XOP_CONTAINERS_H
