#include "ZeroMQ.h"

// variable zeromq_send(string msg, variable client_or_server)
extern "C" int zeromq_client_send(zeromq_client_sendParams *p)
{
  BEGIN_OUTER_CATCH

  const auto msg = GetStringFromHandle(p->msg);
  DisposeHandle(p->msg);

  ZeroMQClientSend(msg);

  END_OUTER_CATCH
}
