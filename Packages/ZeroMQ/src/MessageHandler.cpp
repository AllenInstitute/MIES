#include "ZeroMQ.h"
#include "MessageHandler.h"
#include "RequestInterface.h"

#include <thread>
#include <chrono>

namespace
{

using namespace std::chrono_literals;
std::recursive_mutex threadMutex;
ConcurrentQueue<RequestInterfacePtr> reqQueue;
bool threadShouldFinish;
std::recursive_mutex threadShouldFinishMutex;

void WorkerThread()
{
  DebugOutput(fmt::sprintf("%s: Begin WorkerThread() with thread_id=%d.\r",
                           __func__, std::this_thread::get_id()));

  {
    // initialize to false
    LockGuard lock(threadShouldFinishMutex);
    threadShouldFinish = false;
  }

  zmq_msg_t identityMsg, payloadMsg;
  int rc;

  rc = zmq_msg_init(&identityMsg);
  ZEROMQ_ASSERT(rc == 0);

  rc = zmq_msg_init(&payloadMsg);
  ZEROMQ_ASSERT(rc == 0);

  for(;;)
  {
    try
    {
      // check if stop is requested
      {
        LockGuard lock(threadShouldFinishMutex);
        if(threadShouldFinish)
        {
          DebugOutput(fmt::sprintf("%s: Exiting.\r", __func__));
          break;
        }
      }

      auto numBytes = ZeroMQServerReceive(&identityMsg, &payloadMsg);

      if(numBytes == -1 && zmq_errno() == EAGAIN) // timeout
      {
        std::this_thread::sleep_for(10ms);
        continue;
      }

      ZEROMQ_ASSERT(numBytes >= 0);

      DebugOutput(fmt::sprintf("%s: numBytes=%d\r", __func__, numBytes));

      const auto identity = CreateStringFromZMsg(&identityMsg);

      try
      {
        const auto payload = CreateStringFromZMsg(&payloadMsg);
        reqQueue.push(std::make_shared<RequestInterface>(identity, payload));
      }
      catch(const IgorException &e)
      {
        auto docTemplate = R"( {
                 "errorCode" : {
                   "value" : %d,
                   "msg"   : "%s"
                   }
                 }
                 )";

        auto reply =
            json::parse(fmt::sprintf(docTemplate, e.m_errorCode, e.what()))
                .dump(4);

        rc = ZeroMQServerSend(identity, reply);

        DebugOutput(
            fmt::sprintf("%s: ZeroMQSendAsServer returned %d\r", __func__, rc));
      }
    }
    catch(const std::exception &e)
    {
      XOPNotice_ts(fmt::sprintf(
          "%s: Caught std::exception with what=\"%s\". This must NOT happen!\r",
          __func__, e.what()));
    }
    catch(...)
    {
      XOPNotice_ts(fmt::sprintf("%s: Caught exception. This must NOT happen!\r",
                                __func__));
    }
  }

  // ignore errors
  zmq_msg_close(&identityMsg);
  zmq_msg_close(&payloadMsg);
}

void CallAndReply(RequestInterfacePtr req) noexcept
{
  try
  {
    req->CanBeProcessed();
    auto reply = req->Call();
    ZeroMQServerSend(req->GetCallerIdentity(), reply.dump(4));
  }
  catch(const IgorException &e)
  {
    auto docTemplate = R"( {
             "errorCode" : {
               "value" : %d,
               "msg"   : "%s"
               }
             }
             )";

    auto reply =
        json::parse(fmt::sprintf(docTemplate, e.m_errorCode, e.what()));

    if(req->HasValidMessageId())
    {
      reply[MESSAGEID_KEY] = req->GetMessageId();
    }

    auto rc = ZeroMQServerSend(req->GetCallerIdentity(), reply.dump(4));

    // handle host unreachable error

    DebugOutput(
        fmt::sprintf("%s: ZeroMQSendAsServer returned %d\r", __func__, rc));
  }
  catch(const std::exception &e)
  {
    XOPNotice_ts(fmt::sprintf(
        "%s: Caught std::exception with what=\"%s\". This must NOT happen!\r",
        __func__, e.what()));
  }
  catch(...)
  {
    XOPNotice_ts(fmt::sprintf("%s: Caught exception. This must NOT happen!\r",
                              __func__));
  }
}

} // anonymous namespace

void MessageHandler::StartHandler()
{
  LockGuard lock(threadMutex);

  if(m_thread.joinable())
  {
    throw IgorException(HANDLER_ALREADY_RUNNING);
  }

  DebugOutput(fmt::sprintf("%s: Trying to start the handler.\r", __func__));

  if(!GlobalData::Instance().HasBinds())
  {
    throw IgorException(HANDLER_NO_CONNECTION);
  }

  DebugOutput(fmt::sprintf("%s: Before WorkerThread() start.\r", __func__));

  auto t = std::thread(WorkerThread);
  m_thread.swap(t);
}

void MessageHandler::StopHandler()
{
  LockGuard lock(threadMutex);

  if(!m_thread.joinable())
  {
    return;
  }

  DebugOutput(fmt::sprintf("%s: Shutting down the handler.\r", __func__));

  {
    LockGuard lock(threadShouldFinishMutex);
    threadShouldFinish = true;
  }

  m_thread.join();
}

void MessageHandler::HandleAllQueuedMessages()
{
  if(!RunningInMainThread() || reqQueue.empty())
  {
    return;
  }

  reqQueue.apply_to_all(CallAndReply);
}

MessageHandler::~MessageHandler()
{
  StopHandler();
}
