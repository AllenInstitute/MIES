#include "ZeroMQ.h"
#include "RequestInterface.h"
#include "CallFunctionOperation.h"

// string zeromq_test_callfunction(string msg)
extern "C" int zeromq_test_callfunction(zeromq_test_callfunctionParams *p)
{
  BEGIN_OUTER_CATCH

  auto msg = GetStringFromHandle(p->msg);
  WMDisposeHandle(p->msg);

  DebugOutput(fmt::sprintf("%s: input=%s\r", __func__, msg));

  auto retMessage = CallIgorFunctionFromMessage(msg);

  auto len = retMessage.size();

  DebugOutput(fmt::sprintf("%s: len=%d, retMessage=%.255s\r", __func__, len,
                           retMessage));

  p->result = WMNewHandle(len);
  ASSERT(p->result != nullptr);
  memcpy(*(p->result), retMessage.c_str(), len);

  END_OUTER_CATCH
}
