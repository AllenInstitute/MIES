#include "ZeroMQ.h"

// variable zeromq_server_send(string identity, string msg)
extern "C" int zeromq_server_send(zeromq_server_sendParams *p)
{
  BEGIN_OUTER_CATCH

  const auto identity = GetStringFromHandle(p->identity);
  WMDisposeHandle(p->identity);

  const auto msg = GetStringFromHandle(p->msg);
  WMDisposeHandle(p->msg);

  ZeroMQServerSend(identity, msg);

  END_OUTER_CATCH
}
