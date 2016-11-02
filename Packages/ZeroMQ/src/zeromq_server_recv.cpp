#include "ZeroMQ.h"

// string zeromq_server_recv(string *identity)
extern "C" int zeromq_server_recv(zeromq_server_recvParams *p)
{
  BEGIN_OUTER_CATCH

  int numBytes, rc;
  zmq_msg_t payloadMsg, identityMsg;

  rc = zmq_msg_init(&payloadMsg);
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_msg_init(&identityMsg);
  ZEROMQ_ASSERT(rc == 0);

  auto doBusyWait = GlobalData::Instance().GetRecvBusyWaitingFlag();

  for(;;)
  {
    numBytes = ZeroMQServerReceive(&identityMsg, &payloadMsg);

    if(numBytes == -1 && zmq_errno() == EAGAIN) // timeout
    {
      if(!doBusyWait ||
         SpinProcess()) // user requested abort or we should not wait
      {
        InitHandle(&(p->result), 0);
        InitHandle(p->identity, 0);
        break;
      }

      if(RunningInMainThread())
      {
        XOPSilentCommand("DoXOPIdle");
      }

      continue;
    }

    ZEROMQ_ASSERT(numBytes >= 0);

    WriteZMsgIntoHandle(&(p->result), &payloadMsg);
    WriteZMsgIntoHandle(p->identity, &identityMsg);

    auto identity = CreateStringFromZMsg(&identityMsg);
    auto msg      = CreateStringFromZMsg(&payloadMsg);

    DebugOutput(fmt::sprintf("%s: numBytes=%d, identity=%s, msg=%.255s\r",
                             __func__, numBytes, identity, msg));
    break;
  }

  rc = zmq_msg_close(&payloadMsg);
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_msg_close(&identityMsg);
  ZEROMQ_ASSERT(rc == 0);

  END_OUTER_CATCH
}
