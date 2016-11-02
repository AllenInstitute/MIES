#pragma once

#include <mutex>
#include "ConcurrentQueue.h"

class GlobalData
{
public:
  /// Access to singleton-type global object
  static GlobalData &Instance()
  {
    static GlobalData globData;
    return globData;
  }

  void *ZMQClientSocket();
  bool HasClientSocket();

  void *ZMQServerSocket();
  bool HasServerSocket();

  void SetDebugFlag(bool val);
  bool GetDebugFlag();

  void SetRecvBusyWaitingFlag(bool val);
  bool GetRecvBusyWaitingFlag();

  void CloseConnections();
  bool HasBinds();
  void AddToListOfBinds(std::string localPoint);
  bool HasConnections();
  void AddToListOfConnections(std::string remotePoint);
  void EnsureInteropProcFileAvailable();
  ConcurrentQueue<std::string> &GetXOPNoticeQueue();

  std::recursive_mutex m_clientMutex, m_serverMutex;

private:
  GlobalData();
  ~GlobalData();
  GlobalData(const GlobalData &) = delete;
  GlobalData &operator=(const GlobalData &) = delete;

  void *zmq_context;
  void *zmq_client_socket;
  void *zmq_server_socket;
  std::vector<std::string> m_binds, m_connections;
  std::recursive_mutex m_settingsMutex;

  bool m_debugging;
  bool m_busyWaiting;

  ConcurrentQueue<std::string> m_queue;
};
