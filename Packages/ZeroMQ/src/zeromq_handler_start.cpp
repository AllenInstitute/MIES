#include "ZeroMQ.h"
#include "MessageHandler.h"

// variable zeromq_handler_start()
extern "C" int zeromq_handler_start(zeromq_handler_startParams *p)
{
  BEGIN_OUTER_CATCH

  DebugOutput(fmt::sprintf("%s:\r", __func__));
  MessageHandler::Instance().StartHandler();

  END_OUTER_CATCH
}
