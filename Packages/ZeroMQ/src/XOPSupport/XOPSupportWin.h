﻿// This file contains equates and prototypes that are needed on Windows only.

#ifdef __cplusplus
extern "C" {						/* This allows C++ to call the XOPSupport routines */
#endif

/* Windows-specific routines (in XOPWinSupport.c) */
HMODULE XOPModule(void);
HMODULE IgorModule(void);
HWND IgorClientHWND(void);
void debugstr(const char *text);
int SendWinMessageToIgor(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam, int beforeOrAfter);

#ifdef __cplusplus
}
#endif
