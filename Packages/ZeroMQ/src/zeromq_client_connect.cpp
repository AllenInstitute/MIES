#include "ZeroMQ.h"

// variable zeromq_client_connect(string remotePoint)
extern "C" int zeromq_client_connect(zeromq_client_connectParams *p)
{
  BEGIN_OUTER_CATCH

  const auto remotePoint = GetStringFromHandle(p->remotePoint);
  DisposeHandle(p->remotePoint);
  p->remotePoint = nullptr;

  GET_CLIENT_SOCKET(socket);
  const auto rc = zmq_connect(socket.get(), remotePoint.c_str());
  ZEROMQ_ASSERT(rc == 0);

  DebugOutput(
      fmt::sprintf("%s: remotePoint=%s, rc=%d\r", __func__, remotePoint, rc));
  GlobalData::Instance().AddToListOfConnections(GetLastEndPoint(socket.get()));

  END_OUTER_CATCH
}
