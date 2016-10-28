#include "ZeroMQ.h"
#include "MessageHandler.h"

namespace
{

bool idleInProgress = false;

} // anonymous namespace

/*	XOPEntry()
  This is the entry point from the host application to the XOP for all messages
  after the INIT message.
*/
extern "C" void XOPEntry()
{
  try
  {
    switch(GetXOPMessage())
    {
    case FUNCADDRS:
    {
      auto result = RegisterFunction();
      SetXOPResult(result);
    }
    break;
    case IDLE:
      if(!idleInProgress)
      {
        idleInProgress = true;
        MessageHandler::Instance().HandleAllQueuedMessages();
        OutputQueuedNotices();
        idleInProgress = false;
      }
      break;
    case CLEANUP:
      DebugOutput(fmt::sprintf("%s: CLEANUP\r", __func__));
      MessageHandler::Instance().StopHandler();
      GlobalData::Instance().CloseConnections();
      break;
    }
  }
  catch(...)
  {
    XOPNotice_ts(fmt::sprintf("%s: Caught exception. This must NOT happen!\r",
                              __func__));
  }
}

/*	XOPMain(ioRecHandle)

  This is the initial entry point at which the host application calls XOP.
  The message sent by the host must be INIT.

  XOPMain does any necessary initialization and then sets the XOPEntry field of
  the ioRecHandle to the address to be called for future messages.
*/

HOST_IMPORT int XOPMain(IORecHandle ioRecHandle)
{
  try
  {
    XOPInit(ioRecHandle);  // Do standard XOP initialization
    SetXOPEntry(XOPEntry); // Set entry point for future calls

    SetXOPType(RESIDENT | IDLE);

    if(igorVersion < 701)
    {
      SetXOPResult(OLD_IGOR);
      return EXIT_FAILURE;
    }

    GlobalData::Instance();

#ifdef _DEBUG
    ApplyFlags(ZeroMQ_SET_FLAGS::DEBUG);
#endif // _DEBUG

    SetXOPResult(EXIT_SUCCESS);
    return EXIT_SUCCESS;
  }
  catch(const IgorException &e)
  {
    SetXOPResult(e.m_errorCode);
    return EXIT_FAILURE;
  }
  catch(...)
  {
    SetXOPResult(UNHANDLED_CPP_EXCEPTION);
    return EXIT_FAILURE;
  }
}
