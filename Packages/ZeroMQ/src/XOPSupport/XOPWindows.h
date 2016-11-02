// For XOPs that add windows to Igor

#ifndef XOP_WINDOWS_H
#define XOP_WINDOWS_H

#ifdef __cplusplus
extern "C" {
#endif

#pragma pack(2)	// All structures passed to Igor are two-byte aligned.

/*	Windowed XOP message codes, passed from host to XOP.
	These messages are used in XOP Toolkit 7 and later with Igor Pro 7 and later.
	They do not work with XOPs written with XOP Toolkit 6 and before which
	use a different and incompatible XOP window protocol.
*/

// These are used by window XOPs to distinguish window messages from other messages
#define kXOPWindowMessageFirst 1000
#define kXOPWindowMessageLast 1299

enum {
	// General Window Messages
	kXOPWindowMessageGeneralStart = 1000,
	kXOPWindowMessageActivate = kXOPWindowMessageGeneralStart,
	kXOPWindowMessageUpdate,
	kXOPWindowMessageResized,
	kXOPWindowMessageMoved,
	kXOPWindowMessageZoom,				// Not implemented. Qt automatically zooms windows to fill the screen.
	kXOPWindowMessageSetSizeLimits,
	kXOPWindowMessageGetPreferredRect,
	kXOPWindowMessageUpdateFileMenu,
	kXOPWindowMessageUpdateEditMenu,
	kXOPWindowMessageUpdateWindowsMenu,
	kXOPWindowMessageRenamed,			// The window was renamed
	kXOPWindowMessageWindowBeingKilled,
	kXOPWindowMessageGeneralEnd,

	// File Menu Messages
	kXOPWindowMessageFileMenuStart = 1100,
	kXOPWindowMessageSaveWindow = kXOPWindowMessageFileMenuStart,
	kXOPWindowMessageSaveWindowAs,
	kXOPWindowMessageSaveWindowCopy,
	kXOPWindowMessageAdoptWindow,
	kXOPWindowMessageRevertWindow,
	kXOPWindowMessageSaveGraphics,
	kXOPWindowMessagePageSetup,
	kXOPWindowMessagePrint,
	kXOPWindowMessagePrintPreview,
	kXOPWindowMessageFileMenuEnd,

	// Edit Menu Messages
	kXOPWindowMessageEditMenuStart = 1125,
	kXOPWindowMessageDuplicate = kXOPWindowMessageEditMenuStart,		// Duplicate works on the window as a whole, not on the container, so it is here rather than in XOPContainers.h
	kXOPWindowMessageExportGraphics,									// Export Graphics operates on the window as a whole, like Save Graphics, so it is here rather than in XOPContainers.h.
	kXOPWindowMessageEditMenuEnd,

	// Window Menu Messages
	kXOPWindowMessageWindowsMenuStart = 1150,
	kXOPWindowMessageCloseMeansHide = kXOPWindowMessageWindowsMenuStart,
	kXOPWindowMessageWindowHidden,
	kXOPWindowMessageWindowShown,
	kXOPWindowMessageCloseWindow,
	kXOPWindowMessageMoveToPreferredPosition,
	kXOPWindowMessageMoveToFullPosition,
	kXOPWindowMessageRetrieveWindow,
	kXOPWindowMessageWindowsMenuEnd,

	// Target Window Messages
	kXOPWindowMessageTargetWindowStart = 1200,
	kXOPWindowMessageGetTargetWindowRef = kXOPWindowMessageTargetWindowStart,
	kXOPWindowMessageSetTargetWindowTitle,		// Not yet tested
	kXOPWindowMessageTargetWindowEnd,
};

typedef enum {									// Used with CreateXOPWindow option parameter
	kCreateXOPWindowNoOptions=0,
	kCreateXOPWindowAsTargetWindow=1,
} CreateXOPWindowOptionType;

typedef enum {		// Used as parameter to GetIgorWindowInfo and SetIgorWindowInfo
	kXOPWindowNSView=1,							// Read-only, valid on Macintosh only, valid only for XOP-created container
	kXOPWindowHWND,								// Read-only, valid on Windows only, valid only for XOP-created container
	kXOPWindowQWidget,							// Read-only, for wizards only, valid only for XOP-created container
	kXOPWindowXOPPointer,						// Read/write, defaults to NULL
	kIgorWindowWinType,							// Read-only, returns winType (XOPWIN or XOPTARGWIN) via int*
	kIgorWindowWinName,							// Read-only, returns winName via char*
	kIgorWindowBoundsInPixels,					// Read-only, returns bounds of content area via Rect*
	kIgorWindowHiddenState,						// Read-only, returns hidden state via int*
	kIgorWindowKillMode,						// Read/write, via int*; See XOPWindowKillMode enum
} IgorWindowInfoType;

typedef enum {		// For kIgorWindowKillMode parameter
	kIgorWindowKillModeNormal=0,				// Displays Save dialog
	kIgorWindowKillModeJustKill=1,				// Kills without saving or dialog
	kIgorWindowKillModeNoKill=2,				// Refuses to kill
	kIgorWindowKillModeJustHide=3,				// Hides instead of killing
} IgorWindowKillMode;

#pragma pack()	// Reset structure alignment to default.

#ifdef __cplusplus
}
#endif

#endif	// XOP_WINDOWS_H
