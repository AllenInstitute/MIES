#include "ZeroMQ.h"

// variable zeromq_server_bind(string localPoint)
extern "C" int zeromq_server_bind(zeromq_server_bindParams *p)
{
  BEGIN_OUTER_CATCH

  const auto localPoint = GetStringFromHandle(p->localPoint);
  DisposeHandle(p->localPoint);
  p->localPoint = nullptr;

  GET_SERVER_SOCKET(socket);
  const auto rc = zmq_bind(socket.get(), localPoint.c_str());
  ZEROMQ_ASSERT(rc == 0);

  DebugOutput(
      fmt::sprintf("%s: localPoint=%s, rc=%d\r", __func__, localPoint, rc));
  GlobalData::Instance().AddToListOfBinds(GetLastEndPoint(socket.get()));

  END_OUTER_CATCH
}
