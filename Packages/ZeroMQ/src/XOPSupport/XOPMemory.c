// XOPMemory.c - Support routines for Igor XOPs

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	WM Memory XOPSupport Routines

	The WM memory XOPSupport routines provide a mechanism by which Igor and XOPs can
	exchange memory-reference objects in a compatible way. For example, a Handle
	is used by Igor to pass a string parameter to an external function and by an XOP
	to return a string result from an external function to Igor. For this to work, an
	Igor Handle and an XOP Handle must be compatible, which means that Igor and XOPs
	must use the same functions for allocating and disposing Handles.

	Historically on Macintosh, Igor and XOPs always used native Macintosh Handles and consequently
	used native Mac OS routines such as NewHandle, GetHandleSize, SetHandleSize, and DisposeHandle.
	On Windows, they always used WaveMetrics emulation routines with the same names, implemented
	in Igor and exported to XOPs through the IGOR.lib and IGOR64.lib files.
	
	Native Macintosh Handles are limited by Mac OS to roughly 2 GB. This is unfortunately
	true even when running a 64-bit application. WaveMetrics emulation of Macintosh Handles
	never had this limitation.
	
	Igor Pro 7 was the first version of Igor that ran in 64 bits on Macintosh and XOP Toolkit 7.00
	was the first version of the XOP Toolkit that supported compilation of 64-bit Macintosh XOPs.
	
	Working with the 64-bit version of MacIgor7 over time, we noticed that the Mac OS 2 GB
	limitation sometimes caused problems. To overcome this limit, starting with Igor8,
	the Macintosh 64-bit version of Igor also uses emulation of Handles. This table summarizes
	Igor's use of Handles:
	
							Igor Pro 7 and before		Igor Pro 8 and later

	Mac 32 Bit				Native Macintosh			Native Macintosh
	
	Mac 64 Bit				Native Macintosh			WaveMetrics Emulation
	
	Windows 32 Bit			WaveMetrics Emulation		WaveMetrics Emulation
	
	Windows 64 Bit			WaveMetrics Emulation		WaveMetrics Emulation
	
	As the table shows, the only change is that, as of Igor Pro 8, Igor uses its own emulation
	of Handles when running on Macintosh in 64 bits.
 
	For Handles passed between Igor and XOPs, such as for string parameters and string result,
	Igor and XOPs must use the same implementation of Handles. For example, if Igor
	allocates such a Handle to pass a parameter to an XOP, the XOP needs to call a function
	to determine the number of bytes associated with the Handle. The Mac OS native GetHandleSize
	function works only with Handles allocated by the Mac OS native NewHandle function. It does
	not work with Handles allocated by WaveMetrics' emulation of NewHandle. The converse is also
	true. So, when it comes to Handles, Igor and XOPs must use the same set of functions.
	Either both must use native Mac OS functions or both must use WaveMetrics emulation functions.
	
	To make this possible, in XOP Toolkit 7.01, we introduced new routines named WMNewHandle,
	WMGetHandleSize, and so on. XOPs that use these WaveMetrics routines use the correct
	implementation of Handles regardless Igor version and operating system.
	
	Because of the change to Handles in MacIgor64, when running in 64 bits on Macintosh, Igor8
	and later report an error if you attempt to load an XOP created with XOP Toolkit 7.00. You
	must modify such XOPs to use WaveMetrics memory XOPSupport routines instead of Mac OS native
	routines and recompile them using XOP Toolkit 7.01 or later. Existing Macintosh 32-bit XOPs
	and existing Windows 32-bit and 64-bit XOPs continue to work as before.
	
	Windows-only XOPs can be compiled without changes in XOP Toolkit 7.01. However, for
	consistency we recommend that you update even Windows-only XOPs.
	
	To update your XOP to use WM memory XOPSupport routines with XOP Toolkit 7.01 and later,
	follow these steps:
	
	1.	Replace all NewHandle calls with WMNewHandle.
	2.	Replace all GetHandleSize calls with WMGetHandleSize.
	3.	Replace all SetHandleSize calls with WMSetHandleSize.
	4.	Replace all HandToHand calls with WMHandToHand.
	5.	Replace all HandAndHand calls with WMHandAndHand.
	6.	Replace all DisposeHandle calls with WMDisposeHandle.
	7.	Replace all NewPtr calls with WMNewPtr.
	8.	Replace all GetPtrSize calls with WMGetPtrSize.
	9.	Replace all SetPtrSize calls with WMSetPtrSize.
	10.	Replace all PtrToHand calls with WMPtrToHand.
	11.	Replace all PtrAndHand calls with WMPtrAndHand.
	12.	Replace all DisposePtr calls with WMDisposePtr.
	13.	Remove all calls to MemError (details below).
	14.	Recompile your XOP.
	
	Most XOPs call only a few of these routines so the number of changes required
	will typically be small.
	
	Check your changes carefully. If you fail to replace, for example, NewHandle with WMNewHandle,
	you will get a link error when you build on Macintosh. The error occurs because of #defines
	in XOPMacSupport.h designed to make you aware if you forget to replace a Mac OS native call
	with the corresponding WM memory XOPSupport routine call.

	The resulting XOP will continue to work correctly with versions of Igor6 or Igor7
	that it previously worked with. The only difference is that it will now also work correctly
	with Igor8 in 64 bits on Macintosh.
	
	There are some differences between the WM memory XOPSupport routines and the corresponding
	Macintosh routines:
	
	1.	WMSetHandleSize and WMSetPtrSize return an error code while the corresponding native
		Macintosh routines do not.
	
	2.	There is no WMMemError function corresponding to the native Macintosh MemError function.
		If you have a call to MemError, replace it like this:
		
		OLD									NEW
			SetHandleSize(h, newSize);		err = WMSetHandleSize(h, newSize);
			err = MemError();
	
	3.	WMDisposeHandle and WMDisposePtr do nothing if passed a NULL parameter while the corresponding
		native Macintosh routines treat this as an error (nilHandleErr) which MemError returns.
	
	It is unlikely that you call any native Mac OS routines that return Handles. However
	if you do, you must treat such native Mac OS Handles differently. You must use native
	Mac OS functions, not WaveMetrics memory XOPSupport routines, on native Mac OS Handles.
	In this case, you must #define ALLOW_MAC_OS_NATIVE_MEMORY_ROUTINES as otherwise the
	#defines in XOPWinMacSupport.h will prevent you from using native Mac OS functions.

	If you find it necessary to define ALLOW_MAC_OS_NATIVE_MEMORY_ROUTINES, be very careful.
	If you pass a Mac OS native Handle to Igor, or if you pass a WM handle to Mac OS, you
	are likely to corrupt memory, causing a crash that is very hard to track down.
*/

const int gWMMemoryFunctionsVersion = 800;		// This structure represents the WMMemory functions known as of Igor Pro version 8.00
#pragma pack(2)	// All structures passed between Igor and XOP are two-byte aligned.
struct WMMemoryFunctions {
	// Start of functions provided by Igor Pro 8.00 and later

	// Handle functions
	Handle (*pWMNewHandle)(BCInt numBytes);								// Address of Igor's WMNewHandle function or NULL
	BCInt (*pWMGetHandleSize)(Handle h);								// Address of Igor's WMGetHandleSize function or NULL
	int (*pWMSetHandleSize)(Handle h, BCInt numBytes);					// Address of Igor's WMSetHandleSize function or NULL
	int (*pWMHandToHand)(Handle* hPtr);									// Address of Igor's WMHandToHand function or NULL
	int (*pWMHandAndHand)(Handle h1, Handle h2);						// Address of Igor's WMHandAndHand function or NULL
	void (*pWMDisposeHandle)(Handle h);									// Address of Igor's WMDisposeHandle function or NULL

	// Pointer functions
	void* (*pWMNewPtr)(BCInt numBytes);									// Address of Igor's WMNewPtr function or NULL
	BCInt (*pWMGetPtrSize)(void* p);									// Address of Igor's WMGetPtrSize function or NULL
	int (*pWMSetPtrSize)(void* p, BCInt numBytes);						// Address of Igor's WMSetPtrSize function or NULL
	int (*pWMPtrToHand)(const void* p, Handle* hPtr, BCInt numBytes);	// Address of Igor's WMPtrToHand function or NULL
	int (*pWMPtrAndHand)(const void* p, Handle h, BCInt numBytes);		// Address of Igor's WMPtrAndHand function or NULL
	void (*pWMDisposePtr)(void* p);										// Address of Igor's WMDisposePtr function or NULL
	
	// End of functions provided by Igor Pro 8.00 and later
};
typedef struct WMMemoryFunctions WMMemoryFunctions;
#pragma pack()	// Restore default structure packing
static struct WMMemoryFunctions gWMMemoryFunctions = {0};		// Initialize all fields to 0

/*	InitWMMemory()

	InitWMMemory is called only by XOPInit. It sets the address of memory-related functions
	used by the WM memory XOPSupport routines (WMNewHandle, WMDisposeHandle, ...).
	
	As of Igor Pro 8.00, this routine sets the fields of gWMMemoryFunctions only on 64-bit Macintosh.
	When running on Windows or on 32-bit Macintosh, the fields remain set to zero which causes the
	WM memory XOPSupport routines to continue to work as before Igor8. This table shows the type
	of routines called by the WM memory XOPSupport routines:
	
						Running with Igor7 or before	Running with Igor8 or later
	Mac 32 bit			Native Mac OS routines			Native Mac OS routines
	Mac 64 bit			Native Mac OS routines			WM memory routines
	Windows 32 bit		WM memory routines				WM memory routines
	Windows 64 bit		WM memory routines				WM memory routines
	
	Future versions of Igor may behave differently but this will not affect XOPs that use
	the WM memory XOPSupport routines.
	
	See WM Memory XOPSupport Routines for details.
*/
void
InitWMMemory()
{
	if (igorVersion < 800)
		return;
	CallBack4(GET_IGOR_INTERNAL_INFO, (void*)"WMMemoryFunctions", (void*)NULL, XOP_CALLBACK_INT(gWMMemoryFunctionsVersion), (void*)&gWMMemoryFunctions);
	return;
}

Handle
WMNewHandle(BCInt numBytes)					// See WM Memory XOPSupport Routines for details
{
	Handle h;
	if (gWMMemoryFunctions.pWMNewHandle == NULL) {
		#undef NewHandle					// Remove definition from XOPSupportMac.h
		h = NewHandle(numBytes);
	}
	else {
		h = gWMMemoryFunctions.pWMNewHandle(numBytes);
	}
	return h;
}

BCInt
WMGetHandleSize(Handle h)					// See WM Memory XOPSupport Routines for details
{
	BCInt numBytes;
	if (gWMMemoryFunctions.pWMGetHandleSize == NULL) {
		#undef GetHandleSize				// Remove definition from XOPSupportMac.h
		numBytes = GetHandleSize(h);
	}
	else {
		numBytes = gWMMemoryFunctions.pWMGetHandleSize(h);
	}
	return numBytes;
}

int
WMSetHandleSize(Handle h, BCInt numBytes)	// See WM Memory XOPSupport Routines for details
{
	int err;
	if (gWMMemoryFunctions.pWMSetHandleSize == NULL) {
		#undef SetHandleSize				// Remove definition from XOPSupportMac.h
		SetHandleSize(h, numBytes);
		#undef MemError						// Remove definition from XOPSupportMac.h
		err = MemError();
	}
	else {
		err = gWMMemoryFunctions.pWMSetHandleSize(h, numBytes);
	}
	return err;
}

int
WMHandToHand(Handle* hPtr)					// See WM Memory XOPSupport Routines for details
{
	int err;
	if (gWMMemoryFunctions.pWMHandToHand == NULL) {
		#undef HandToHand					// Remove definition from XOPSupportMac.h
		err = HandToHand(hPtr);
	}
	else {
		err = gWMMemoryFunctions.pWMHandToHand(hPtr);
	}
	return err;
}

int
WMHandAndHand(Handle h1, Handle h2)			// See WM Memory XOPSupport Routines for details
{
	// Concatenates contents of h1 onto h2
	int err;
	if (gWMMemoryFunctions.pWMHandAndHand == NULL) {
		#undef HandAndHand					// Remove definition from XOPSupportMac.h
		err = HandAndHand(h1, h2);
	}
	else {
		err = gWMMemoryFunctions.pWMHandAndHand(h1, h2);
	}
	return err;
}

void
WMDisposeHandle(Handle h)					// See WM Memory XOPSupport Routines for details
{
	if (h == NULL)
		return;
	if (gWMMemoryFunctions.pWMDisposeHandle == NULL) {
		#undef DisposeHandle				// Remove definition from XOPSupportMac.h
		DisposeHandle(h);
	}
	else {
		gWMMemoryFunctions.pWMDisposeHandle(h);
	}
}

void*
WMNewPtr(BCInt numBytes)					// See WM Memory XOPSupport Routines for details
{
	void* p;
	if (gWMMemoryFunctions.pWMNewPtr == NULL) {
		#undef NewPtr						// Remove definition from XOPSupportMac.h
		p = (void*)NewPtr(numBytes);
	}
	else {
		p = gWMMemoryFunctions.pWMNewPtr(numBytes);
	}
	return p;
}

BCInt
WMGetPtrSize(void* p)						// See WM Memory XOPSupport Routines for details
{
	BCInt numBytes;
	if (gWMMemoryFunctions.pWMGetPtrSize == NULL) {
		#undef GetPtrSize					// Remove definition from XOPSupportMac.h
		numBytes = GetPtrSize((Ptr)p);
	}
	else {
		numBytes = gWMMemoryFunctions.pWMGetPtrSize(p);
	}
	return numBytes;
}

int
WMSetPtrSize(void* p, BCInt numBytes)		// See WM Memory XOPSupport Routines for details
{
	int err;
	if (gWMMemoryFunctions.pWMSetPtrSize == NULL) {
		#undef SetPtrSize					// Remove definition from XOPSupportMac.h
		SetPtrSize((Ptr)p, numBytes);
		#undef MemError						// Remove definition from XOPSupportMac.h
		err = MemError();
	}
	else {
		err = gWMMemoryFunctions.pWMSetPtrSize(p, numBytes);
	}
	return err;
}

int
WMPtrToHand(const void* p, Handle* hPtr, BCInt numBytes)	// See WM Memory XOPSupport Routines for details
{
	// Sets *hPtr to a newly-allocated handle containing numBytes of memory pointed to by p
	int err;
	if (gWMMemoryFunctions.pWMPtrToHand == NULL) {
		#undef PtrToHand					// Remove definition from XOPSupportMac.h
		err = PtrToHand(p, hPtr, numBytes);
	}
	else {
		err = gWMMemoryFunctions.pWMPtrToHand(p, hPtr, numBytes);
	}
	return err;
}

int
WMPtrAndHand(const void* p, Handle h, BCInt numBytes)		// See WM Memory XOPSupport Routines for details
{
	// Concatenates numBytes of memory pointed to by p onto existing Handle h
	int err;
	if (gWMMemoryFunctions.pWMPtrAndHand == NULL) {
		#undef PtrAndHand					// Remove definition from XOPSupportMac.h
		err = PtrAndHand(p, h, numBytes);
	}
	else {
		err = gWMMemoryFunctions.pWMPtrAndHand(p, h, numBytes);
	}
	return err;
}

void
WMDisposePtr(void* p)						// See WM Memory XOPSupport Routines for details
{
	if (p == NULL)
		return;
	if (gWMMemoryFunctions.pWMDisposePtr == NULL) {
		#undef DisposePtr					// Remove definition from XOPSupportMac.h
		DisposePtr((Ptr)p);
	}
	else {
		gWMMemoryFunctions.pWMDisposePtr(p);
	}
}

