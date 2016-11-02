#include "RequestInterface.h"
#include "CallFunctionOperation.h"

namespace
{

const size_t MAX_MESSAGEID_LENGTH = 255;

bool IsValidMessageId(std::string messageId)
{
  return messageId.length() != 0 && messageId.length() <= MAX_MESSAGEID_LENGTH;
}

} // anonymous namespace

RequestInterface::RequestInterface(std::string callerIdentity,
                                   std::string payload)
    : m_callerIdentity(callerIdentity)
{
  try
  {
    auto doc = json::parse(payload);
    DebugOutput(fmt::sprintf("%s: JSON Document is valid, data=%s.\r", __func__,
                             doc.dump(-1)));
    FillFromJSON(doc);
  }
  catch(const IgorException &)
  {
    throw;
  }
  catch(const std::exception &)
  {
    throw RequestInterfaceException(REQ_INVALID_JSON_OBJECT);
  }
}

RequestInterface::RequestInterface(std::string payload)
    : RequestInterface("", payload)
{
}

void RequestInterface::CanBeProcessed() const
{
  ASSERT(m_op);
  m_op->CanBeProcessed();
}

json RequestInterface::Call() const
{
  ASSERT(m_op);
  auto reply = m_op->Call();

  if(HasValidMessageId())
  {
    reply[MESSAGEID_KEY] = GetMessageId();
  }

  return reply;
}

std::string RequestInterface::GetCallerIdentity() const
{
  return m_callerIdentity;
}

std::string RequestInterface::GetMessageId() const
{
  return m_messageId;
}

bool RequestInterface::HasValidMessageId() const
{
  return IsValidMessageId(m_messageId);
}

void RequestInterface::FillFromJSON(json j)
{
  auto it = j.find("version");

  if(it == j.end() || !it.value().is_number_integer())
  {
    throw RequestInterfaceException(REQ_INVALID_VERSION);
  }

  auto version = it.value().get<int>();

  if(version != 1)
  {
    throw RequestInterfaceException(REQ_INVALID_VERSION);
  }

  m_version = version;

  it = j.find(MESSAGEID_KEY);

  if(it != j.end()) // messageID is optional
  {
    if(!it.value().is_string())
    {
      throw RequestInterfaceException(REQ_INVALID_MESSAGEID);
    }

    auto messageId = it.value().get<std::string>();

    if(!IsValidMessageId(messageId))
    {
      throw RequestInterfaceException(REQ_INVALID_MESSAGEID);
    }

    m_messageId = messageId;
  }

  it = j.find("CallFunction");

  if(it == j.end() || !it.value().is_object())
  {
    throw RequestInterfaceException(REQ_INVALID_OPERATION);
  }

  m_op = std::make_shared<CallFunctionOperation>(*it);

  DebugOutput(fmt::sprintf("%s: Request Object could be created: %s\r",
                           __func__, *this));
}

std::ostream &operator<<(std::ostream &out, RequestInterface req)
{
  fmt::fprintf(
      out, "version=%d, callerIdentity=%s, messageId=%s, CallFunction: {%s}",
      req.m_version, req.m_callerIdentity,
      (req.m_messageId.empty() ? "(not provided)" : req.m_messageId),
      *(req.m_op));

  return out;
}
