#pragma once

/// @param A object name to create
#define GET_CLIENT_SOCKET(A)                                                   \
  SocketWithMutex A(GlobalData::Instance().ZMQClientSocket(),                  \
                    GlobalData::Instance().m_clientMutex);

//DebugOutput(fmt::sprintf("%s: Trying to lock client socket\n", __func__));   \

/// @param A object name to create
#define GET_SERVER_SOCKET(A)                                                   \
  SocketWithMutex A(GlobalData::Instance().ZMQServerSocket(),                  \
                    GlobalData::Instance().m_serverMutex);

//DebugOutput(fmt::sprintf("%s: Trying to lock server socket\n", __func__));   \

class SocketWithMutex
{
public:
  SocketWithMutex(void *s, std::recursive_mutex &mutex)
      : m_lock(mutex), m_plainSocket(s)
  {
    // DebugOutput(fmt::sprintf("%s: Locking %p\n", __func__, m_plainSocket));
  }

  ~SocketWithMutex()
  {
    // DebugOutput(fmt::sprintf("%s: Unlocking %p\n", __func__, m_plainSocket));
  }

  SocketWithMutex(const SocketWithMutex &) = delete;
  SocketWithMutex &operator=(const SocketWithMutex &) = delete;

  void *get()
  {
    return m_plainSocket;
  }

private:
  LockGuard m_lock;
  void *m_plainSocket;
};
