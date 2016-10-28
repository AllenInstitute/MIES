/*	XOPTypes.r -- Type declaration for XOP specific resources

	This file is used for Macintosh XOPs, not for Windows XOPs.
*/

#include "XOPResources.h"		// Load symbols.

/* XOPI Template -- various information about XOP. */
type 'XOPI' {
	integer;							// XOP protocol version. Use XOP_VERSION.
	integer;							// Code for development system used to make XOP. Use DEV_SYS_CODE.
	integer;							// Obsolete. Set to zero.
	integer;							// Obsolete. Set to zero.
	integer;							// XOP Toolkit version. 600 means version 6.00. Use XOP_TOOLKIT_VERSION. Old XOPs will have zero in this field.
};


/* XOPC Template -- information about XOP command line operations. */
type 'XOPC' {
	integer = $$Countof(CmdArray);
	array CmdArray {
		pstring[31];					/* Operation name -- 31 chars max. */
		integer;						/* Operation's category (see #defines below). */
	};
};


/* XMN1 Template -- description of menus added by XOP. */
type 'XMN1' {
	array XMN1Array {
		integer;						/* Resource ID of 'MENU' resource in XOP. */
		integer;						/* Menu flags. See XOPResources.h. */
	};
};


/* XSM1 Template -- description of submenus added by XOP. */
type 'XSM1' {
	array XSM1Array {
		integer;						/* Resource ID of 'MENU' resource in XOP for submenu. */
		integer;						/* Resource ID of 'MENU' resource in XOP for main menu. */
		integer;						/* Number of item in main menu where submenu is to be attached. */
	};
};


/* XMI1 Template -- description of menu items added by XOP to built-in Igor menus. */
type 'XMI1' {
	array XMI1Array {
		integer;						/* Menu ID of built-in Igor menu. See IgorXOP.h for menu IDs. */
		pstring[31];					/* Text for item to be added to menu. */
		integer;						/* Resource ID of 'MENU' resource in XOP for submenu. */
										/* To be attached to menu item or 0 for no submenu. */
		integer;						/* Menu item flags. See XOPResources.h. */
	};
};


/* XOPF Template -- description of functions added by XOP */
type 'XOPF' {
	integer = $$Countof(XFuncArray);	/* Number of functions added by this XOP. */
	array XFuncArray {
		pstring[31];					/* Function name. */
		integer;						/* Function category. See XOPResources.h. */
		integer;						/* Return value type. See XOPResources.h. */
		integer = $$Countof(ParmArray);	/* Number of parameters to this function. */
		array ParmArray {
			integer;					/* Type of this parameter. See XOPResources.h. */
		};
	};
};
