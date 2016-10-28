#include "ZeroMQ.h"

namespace
{

void SetSocketDefaults(void *s)
{
  int val = 0;
  auto rc = zmq_setsockopt(s, ZMQ_LINGER, &val, sizeof(val));
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_setsockopt(s, ZMQ_SNDTIMEO, &val, sizeof(val));
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_setsockopt(s, ZMQ_RCVTIMEO, &val, sizeof(val));
  ZEROMQ_ASSERT(rc == 0);
}

void SetRouterSocketDefaults(void *s)
{
  int val = 1;
  auto rc = zmq_setsockopt(s, ZMQ_ROUTER_MANDATORY, &val, sizeof(val));
  ZEROMQ_ASSERT(rc == 0);

  int64_t bytes = 1024;
  rc            = zmq_setsockopt(s, ZMQ_MAXMSGSIZE, &bytes, sizeof(bytes));
  ZEROMQ_ASSERT(rc == 0);
}

void SetDealerSocketDefaults(void *s)
{
  const char identity[] = "zeromq xop: dealer";
  auto rc = zmq_setsockopt(s, ZMQ_IDENTITY, &identity, strlen(identity));
  ZEROMQ_ASSERT(rc == 0);
}

} // anonymous namespace

GlobalData::GlobalData() : m_busyWaiting(true), m_debugging(false)
{
  zmq_context = zmq_ctx_new();
  ZEROMQ_ASSERT(zmq_context != nullptr);
}

GlobalData::~GlobalData()
{
  // deleting the context is not necessary here.
}

void *GlobalData::ZMQClientSocket()
{
  if(!zmq_client_socket)
  {
    LockGuard lock(m_clientMutex);

    DebugOutput(fmt::sprintf("%s: Creating client socket\n", __func__));

    zmq_client_socket = zmq_socket(zmq_context, ZMQ_DEALER);
    ZEROMQ_ASSERT(zmq_client_socket != nullptr);

    SetSocketDefaults(zmq_client_socket);
    SetDealerSocketDefaults(zmq_client_socket);
  }

  return zmq_client_socket;
}

bool GlobalData::HasClientSocket()
{
  LockGuard lock(m_clientMutex);

  return zmq_client_socket != nullptr;
}

void *GlobalData::ZMQServerSocket()
{
  if(!zmq_server_socket)
  {
    LockGuard lock(m_serverMutex);

    DebugOutput(fmt::sprintf("%s: Creating server socket\n", __func__));

    zmq_server_socket = zmq_socket(zmq_context, ZMQ_ROUTER);
    ZEROMQ_ASSERT(zmq_server_socket != nullptr);

    SetSocketDefaults(zmq_server_socket);
    SetRouterSocketDefaults(zmq_server_socket);
  }

  return zmq_server_socket;
}

bool GlobalData::HasServerSocket()
{
  LockGuard lock(m_serverMutex);

  return zmq_server_socket != nullptr;
}

void GlobalData::SetDebugFlag(bool val)
{
  LockGuard lock(m_settingsMutex);

  DebugOutput(fmt::sprintf("%s: new value=%d\r", __func__, val));
  m_debugging = val;
};

bool GlobalData::GetDebugFlag()
{
  return m_debugging;
}

void GlobalData::SetRecvBusyWaitingFlag(bool val)
{
  LockGuard lock(m_settingsMutex);

  DebugOutput(fmt::sprintf("%s: new value=%d\r", __func__, val));
  m_busyWaiting = val;
}

bool GlobalData::GetRecvBusyWaitingFlag()
{
  return m_busyWaiting;
}

void GlobalData::CloseConnections()
{
  if(HasClientSocket())
  {
    DebugOutput(
        fmt::sprintf("%s: Connections=%d\r", __func__, m_connections.size()));

    try
    {
      // client
      GET_CLIENT_SOCKET(socket);

      for(auto conn : m_connections)
      {
        auto rc = zmq_disconnect(socket.get(), conn.c_str());
        DebugOutput(fmt::sprintf("%s: zmq_disconnect(%s) returned=%d\r",
                                 __func__, conn, rc));
        // ignore errors
      }
      m_connections.clear();

      auto rc = zmq_close(socket.get());
      ZEROMQ_ASSERT(rc == 0);
      zmq_client_socket = nullptr;
    }
    catch(...)
    {
      // ignore errors
    }
  }

  if(HasServerSocket())
  {
    DebugOutput(fmt::sprintf("%s: Binds=%d\r", __func__, m_binds.size()));

    try
    {
      // server
      GET_SERVER_SOCKET(socket);

      for(auto bind : m_binds)
      {
        auto rc = zmq_unbind(socket.get(), bind.c_str());
        DebugOutput(fmt::sprintf("%s: zmq_unbind(%s) returned=%d\r", __func__,
                                 bind, rc));
        // ignore errors
      }
      m_binds.clear();

      auto rc = zmq_close(socket.get());
      ZEROMQ_ASSERT(rc == 0);
      zmq_server_socket = nullptr;
    }
    catch(...)
    {
      // ignore errors
    }
  }
}

void GlobalData::EnsureInteropProcFileAvailable()
{
  if(!RunningInMainThread())
  {
    return;
  }

  const std::string procedure = "ZeroMQ_Interop.ipf";
  Handle listHandle           = NewHandle(0);
  ASSERT(listHandle != nullptr && !MemError());
  auto rc = WinList(listHandle, procedure.c_str(), ";", "");
  ASSERT(rc == 0);

  const auto exists = GetHandleSize(listHandle) > 0;
  DisposeHandle(listHandle);

  if(!exists)
  {
    XOPNotice_ts(fmt::sprintf(
        "The procedure file %s is required for ZeroMQ XOP.", procedure));
    throw IgorException(MISSING_PROCEDURE_FILES);
  }
}

bool GlobalData::HasBinds()
{
  LockGuard lock(m_serverMutex);

  return !m_binds.empty();
}

void GlobalData::AddToListOfBinds(std::string localPoint)
{
  LockGuard lock(m_serverMutex);

  m_binds.push_back(localPoint);
}

bool GlobalData::HasConnections()
{
  LockGuard lock(m_clientMutex);

  return !m_connections.empty();
}

void GlobalData::AddToListOfConnections(std::string remotePoint)
{
  LockGuard lock(m_clientMutex);

  m_connections.push_back(remotePoint);
}

ConcurrentQueue<std::string> &GlobalData::GetXOPNoticeQueue()
{
  return m_queue;
}
