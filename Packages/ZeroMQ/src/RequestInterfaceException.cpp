#include "ZeroMQ.h"

namespace
{

std::string GetErrorMessageFromCode(int errorCode)
{
  switch(errorCode)
  {
  case REQ_UNKNOWN_ERROR:
    return "Unknown error in request interface.";
    break;
  case REQ_INVALID_JSON_OBJECT:
    return "The string is not a valid json object.";
    break;
  case REQ_INVALID_VERSION:
    return "Request interface version is missing or invalid.";
    break;
  case REQ_INVALID_OPERATION:
    return "Unknown operation type.";
    break;
  case REQ_INVALID_OPERATION_FORMAT:
    return "Invalid operation format.";
    break;
  case REQ_INVALID_MESSAGEID:
    return "Invalid optional messageID.";
    break;
  case REQ_OUT_OF_MEMORY:
    return "Request cancelled due to Out Of Memory condition.";
    break;
  case REQ_NON_EXISTING_FUNCTION:
    return "CallFunction: Unknown function.";
    break;
  case REQ_PROC_NOT_COMPILED:
    return "Procedures are not compiled.";
    break;
  case REQ_TOO_FEW_FUNCTION_PARAMS:
    return "CallFunction: Too few parameters.";
    break;
  case REQ_TOO_MANY_FUNCTION_PARAMS:
    return "CallFunction: Too many parameters.";
    break;
  case REQ_UNSUPPORTED_FUNC_SIG:
    return "CallFunction: Unsupported function signature.";
    break;
  case REQ_UNSUPPORTED_FUNC_RET:
    return "CallFunction: Unsupported function return type.";
    break;
  case REQ_INVALID_PARAM_FORMAT:
    return "CallFunction: Parameter is not an array or otherwise invalid.";
    break;
  case REQ_FUNCTION_ABORTED:
    return "CallFunction: The function was partially executed but aborted at "
           "some point.";
    break;
  default:
    ASSERT(0);
    return "unknown error";
    break;
  }
}
} // anonymous namespace

RequestInterfaceException::RequestInterfaceException(int errorCode)
    : IgorException(errorCode, GetErrorMessageFromCode(errorCode))
{
}
