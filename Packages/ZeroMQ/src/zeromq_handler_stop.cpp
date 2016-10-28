#include "ZeroMQ.h"
#include "MessageHandler.h"

// variable zeromq_handler_stop()
extern "C" int zeromq_handler_stop(zeromq_handler_stopParams *p)
{
  BEGIN_OUTER_CATCH

  DebugOutput(fmt::sprintf("%s:\r", __func__));
  MessageHandler::Instance().StopHandler();

  END_OUTER_CATCH
}
