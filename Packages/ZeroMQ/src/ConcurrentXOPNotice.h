#pragma once

#include <string>

/// Thread safe version of XOPNotice, even for private threads
///
/// Remarks:
/// - All threads, also the main thread, must use
///   XOPNotice_ts() so that the messages are ordered
/// - Output to the history should be done at the IDLE event via
///   OutputQueuedNotices(). For that the XOP has to be marked as
///   `SetXOPType(RESIDENT | IDLES);`.

void XOPNotice_ts(std::string str);
void XOPNotice_ts(const char *noticeStr);

void OutputQueuedNotices();
