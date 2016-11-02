/*	This file contains routines that are Windows-specific.
	This file is used only when compiling for Windows.
*/

#include "XOPStandardHeaders.h"			// Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h

/*	XOPModule()

	Returns XOP's module handle.
	
	You will need this HMODULE if your XOP needs to get resources from its own
	executable file using the Win32 FindResource and LoadResource routines. It is
	also needed for other Win32 API routines. 
	
	Thread Safety: XOPModule is thread-safe. It can be called from any thread.
*/
HMODULE
XOPModule(void)
{
	HMODULE hModule;
	
	hModule = GetXOPModule(XOPRecHandle);
	return hModule;
}

/*	IgorModule(void)

	Returns Igor's HINSTANCE.
	
	You will probably never need this.	
	
	Thread Safety: IgorModule is thread-safe. It can be called from any thread.
*/
HMODULE
IgorModule(void)
{
	HMODULE hModule;
	
	hModule = GetIgorModule();
	return hModule;
}

/*	IgorClientHWND(void)

	Returns Igor's MDI client window.
	
	Some Windows calls require that you pass an HWND to identify the owner of a
	new window or dialog. An example is MessageBox. You must pass IgorClientHWND()
	for this purpose.
	
	Thread Safety: IgorClientHWND is thread-safe. It can be called from any thread.
*/
HWND
IgorClientHWND(void)
{
	HWND hwnd;
	
	hwnd = GetIgorClientHWND();
	return hwnd;
}

void
debugstr(const char *text)			// Emulates Macintosh debugstr.
{
	DebugBreak();					// Break into debugger.
}

/*	SendWinMessageToIgor(hwnd, iMsg, wParam, lParam, beforeOrAfter)

	This is for Windows XOPs only.
	
	You must call this twice from your window procedure - once before you process
	the message and once after. You must do this for every message that you
	receive.
	
	This allows Igor to do certain housekeeping operations that are needed so
	that your window will fit cleanly into the Igor environment.
	
	If the result from SendWinMessageToIgor is non-zero, you should skip processing
	of the message. For example, Igor returns non-zero for click and key-related
	messages while an Igor procedure is running.

	To help you understand why this is necessary, here is a description of what
	Igor does with these messages as of this writing.
	
	NOTE: Future versions of Igor may behave differently, so you must send every
	message to Igor, once before you process it and once after.

	WM_CREATE
		Before: Allocates memory used so that XOP window appears in the Windows menu
				and can respond to user actions like Ctrl-E (send behind) and Ctrl-W
				(close).
		After:	Sets a flag saying that the XOP window is ready to interact with Igor.
	
	WM_DESTROY:
		Before:	Nothing.
		After:	Deallocates memory allocated by WM_CREATE.
	
	WM_MDIACTIVATE (when XOP window is being activated only)
		Before:	Compiles procedure window if necessary.
		After:	Sets Igor menu bar (e.g., removes "Graph" menu from Igor menu bar).
	
	Once Igor has processed the WM_CREATE message (after you have processed it),
	Igor may send messages, such as MENUITEM, MENUENABLE, CUT, and COPY, to your
	XOPEntry routines.
	
	Igor does not send the following messages to Windows XOPs, because these kinds
	of matters are handled through the standard Windows OS messages:
		ACTIVATE, UPDATE, GROW, CLICK, KEY, DRAGGED
	
	Thread Safety: SendWinMessageToIgor is not thread-safe.
*/
int
SendWinMessageToIgor(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam, int beforeOrAfter)
{
	HMODULE hModule;
	int result;
	
	hModule = XOPModule();
	result = HandleXOPWinMessage(hModule, hwnd, iMsg, wParam, lParam, beforeOrAfter);
	return result;
}
