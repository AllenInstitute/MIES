#pragma once

#include "ZeroMQ.h"

class MessageHandler
{
public:
  /// Access to singleton-type global object
  static MessageHandler &Instance()
  {
    static MessageHandler obj;
    return obj;
  }

  void StartHandler();
  void StopHandler();
  void HandleAllQueuedMessages();

private:
  MessageHandler() = default;
  ~MessageHandler();
  MessageHandler(const MessageHandler &) = delete;
  MessageHandler &operator=(const MessageHandler &) = delete;

  class thread;
  std::thread m_thread;
};
