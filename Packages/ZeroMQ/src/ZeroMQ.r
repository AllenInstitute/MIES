#include "XOPStandardHeaders.r"

resource 'vers' (1) {						/* XOP version info */
	0x01, 0x00, final, 0x00, 0,				/* version bytes and country integer */
	"1.00",
	"1.00"
};

resource 'vers' (2) {						/* Igor version info */
	0x06, 0x20, release, 0x00, 0,			/* version bytes and country integer */
	"7.01",
	"(for Igor 7.01 or later)"
};

resource 'STR#' (1100) {					/* custom error messages */
	{
  "ZeroMQ requires Igor Pro 7.01 or later.",         // OLD_IGOR
  "Unhandled C++ exception.",                        // UNHANDLED_CPP_EXCEPTION
  "Unknown zeromq_set flag.",                        // UNKNOWN_SET_FLAG
  "Internal error, this should not happen!",         // INTERNAL_ERROR
  "Invalid argument!",                               // INVALID_ARGUMENT
  "Message handler already running.",                // HANDLER_ALREADY_RUNNING
  "Message handler could not find a binded server.", // HANDLER_NO_CONNECTION
  "Can not handle multipart messages.",              // INVALID_MULTIPART_MSG
  "Required procedure files are missing.",           // MISSING_PROCEDURE_FILES
  "Unexpected multi-part message format."            // INVALID_MESSAGE_FORMAT
	}
};

/* no menu item */

resource 'XOPI' (1100) {
	XOP_VERSION,					// XOP protocol version.
	DEV_SYS_CODE,					// Development system information.
	XOP_FEATURE_FLAGS,	  // Tells Igor about XOP features
	XOPI_RESERVED,				// Reserved - must be zero.
	XOP_TOOLKIT_VERSION,	// XOP Toolkit version.
};

#include "functions.r"
