#include "ZeroMQ.h"
#include "CustomExceptions.h"

//--------------------------------------------------------------
// IgorException
//--------------------------------------------------------------

#ifdef WINIGOR
IgorException::IgorException() : m_errorCode(UNHANDLED_CPP_EXCEPTION)
{
}
#endif

IgorException::IgorException(int errorCode) : m_errorCode(errorCode)
{
}

IgorException::IgorException(int errorCode, std::string errorMessage)
    : m_errorCode(errorCode), m_message(std::move(errorMessage))
{
}

const char *IgorException::what() const noexcept
{
  return m_message.c_str();
}

int IgorException::HandleException() const
{
  XOPNotice_ts(what());

  return m_errorCode;
}

//--------------------------------------------------------------
// std::exception
//--------------------------------------------------------------

int HandleException(const std::exception &e)
{
  XOPNotice_ts("Encountered unhandled C++ exception during XOP execution.\r");
  XOPNotice_ts(std::string(e.what()) + CR_STR);

  return UNHANDLED_CPP_EXCEPTION;
}
