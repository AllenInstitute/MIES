#include "ZeroMQ.h"
#include "CallFunctionOperation.h"
#include "CallFunctionParameterHandler.h"
#include "SerializeWave.h"

namespace
{

std::string GetTypeStringForIgorType(int igorType)
{
  switch(igorType)
  {
  case NT_FP64:
    return "variable";
    break;
  case HSTRING_TYPE:
    return "string";
    break;
  case WAVE_TYPE:
    return "wave";
    break;
  case DATAFOLDER_TYPE:
    return "dfref";
    break;
  default:
    ASSERT(0);
    break;
  }
}

std::string ExtractReturnStringFromUnion(IgorTypeUnion *ret, int returnType)
{
  std::string result;
  bool needsQuotes = false;

  switch(returnType)
  {
  case NT_FP64:
    result      = To_stringHighRes(ret->variable);
    needsQuotes = !std::isfinite(ret->variable);
    break;
  case HSTRING_TYPE:
    result = GetStringFromHandle(ret->stringHandle);
    WMDisposeHandle(ret->stringHandle);
    ret->stringHandle = nullptr;
    needsQuotes       = true;
    break;
  case WAVE_TYPE:
    if(ret->waveHandle)
    {
      auto type = WaveType(ret->waveHandle);
      if(type & DATAFOLDER_TYPE || type & WAVE_TYPE)
      {
        throw RequestInterfaceException(REQ_UNSUPPORTED_FUNC_RET);
      }
    }
    result = SerializeWave(ret->waveHandle);
    break;
  case DATAFOLDER_TYPE:
    result      = SerializeDataFolder(ret->dataFolderHandle);
    needsQuotes = true;
    break;
  default:
    ASSERT(0);
    break;
  }

  if(needsQuotes)
  {
    return "\"" + result + "\"";
  }

  return result;
}

} // anonymous namespace

#ifdef MACIGOR

namespace std
{

#endif

std::ostream &operator<<(std::ostream &out, std::vector<std::string> vec)
{
  fmt::fprintf(out, "%s", "[");

  for(auto it = vec.cbegin(); it != vec.cend(); it++)
  {
    if(std::distance(it, vec.cend()) > 1)
    {
      fmt::fprintf(out, "%s, ", *it);
    }
    else
    {
      fmt::fprintf(out, "%s", *it);
    }
  }

  fmt::fprintf(out, "%s", "]");

  return out;
}

#ifdef MACIGOR

} // namespace std

#endif

std::ostream &operator<<(std::ostream &out, CallFunctionOperation op)
{
  fmt::fprintf(out, "name=%s, params=%s", op.m_name, op.m_params);
  return out;
}

CallFunctionOperation::CallFunctionOperation(json j)
{
  DebugOutput(fmt::sprintf("%s: size=%d\r", __func__, j.size()));

  if(j.size() != 1 && j.size() != 2)
  {
    throw RequestInterfaceException(REQ_INVALID_OPERATION_FORMAT);
  }

  // check first element "name"
  auto it = j.find("name");

  if(it == j.end() || !it.value().is_string())
  {
    throw RequestInterfaceException(REQ_INVALID_OPERATION_FORMAT);
  }

  m_name = it.value().get<std::string>();

  if(m_name.empty())
  {
    throw RequestInterfaceException(REQ_NON_EXISTING_FUNCTION);
  }

  it = j.find("params");

  if(it == j.end())
  {
    if(j.size() != 1) // unknown other objects
    {
      throw RequestInterfaceException(REQ_INVALID_OPERATION_FORMAT);
    }

    // no params
    return;
  }

  if(!it.value().is_array())
  {
    throw RequestInterfaceException(REQ_INVALID_PARAM_FORMAT);
  }

  for(const auto &elem : it.value())
  {
    if(elem.is_string())
    {
      m_params.push_back(elem.get<std::string>());
    }
    else if(elem.is_number())
    {
      m_params.push_back(To_stringHighRes(elem.get<double>()));
    }
    else if(elem.is_boolean())
    {
      m_params.push_back(std::to_string(elem.get<bool>()));
    }
    else
    {
      throw RequestInterfaceException(REQ_INVALID_PARAM_FORMAT);
    }
  }

  DebugOutput(
      fmt::sprintf("%s: CallFunction object could be created.\r", __func__));
}

void CallFunctionOperation::CanBeProcessed() const
{
  DebugOutput(fmt::sprintf("%s: Data=%s.\r", __func__, *this));

  FunctionInfo fip;
  auto rc = GetFunctionInfo(m_name.c_str(), &fip);

  // procedures must be compiled
  if(rc == NEED_COMPILE)
  {
    throw RequestInterfaceException(REQ_PROC_NOT_COMPILED);
  }
  // non existing function
  else if(rc == EXPECTED_FUNCTION_NAME)
  {
    throw RequestInterfaceException(REQ_NON_EXISTING_FUNCTION);
  }

  ASSERT(rc == 0);

  const auto numParamsSupplied = static_cast<int>(m_params.size());

  if(numParamsSupplied < fip.numRequiredParameters)
  {
    throw RequestInterfaceException(REQ_TOO_FEW_FUNCTION_PARAMS);
  }
  else if(numParamsSupplied > fip.numRequiredParameters)
  {
    throw RequestInterfaceException(REQ_TOO_MANY_FUNCTION_PARAMS);
  }

  // check passed parameters
  for(auto i = 0; i < numParamsSupplied; i += 1)
  {
    if((fip.parameterTypes[i] & NT_FP64) == NT_FP64)
    {
      char *lastChar;
      std::strtod(m_params[i].c_str(), &lastChar);

      if(*lastChar != '\0')
      {
        throw RequestInterfaceException(REQ_INVALID_PARAM_FORMAT);
      }

      continue;
    }

    if((fip.parameterTypes[i] & HSTRING_TYPE) == HSTRING_TYPE)
    {
      continue;
    }

    if((fip.parameterTypes[i] & DATAFOLDER_TYPE) == DATAFOLDER_TYPE)
    {
      continue;
    }

    throw RequestInterfaceException(REQ_UNSUPPORTED_FUNC_SIG);
  }

  if(fip.returnType != NT_FP64 && fip.returnType != HSTRING_TYPE &&
     fip.returnType != WAVE_TYPE && fip.returnType != DATAFOLDER_TYPE)
  {
    throw RequestInterfaceException(REQ_UNSUPPORTED_FUNC_RET);
  }

  DebugOutput(fmt::sprintf("%s: Request Object can be processed.\r", __func__));
}

json CallFunctionOperation::Call() const
{
  DebugOutput(fmt::sprintf("%s: Data=%s.\r", __func__, *this));

  FunctionInfo fip;
  auto rc = GetFunctionInfo(m_name.c_str(), &fip);
  ASSERT(rc == 0);

  ASSERT(sizeof(fip.parameterTypes) / sizeof(int) == MAX_NUM_PARAMS);
  ASSERT(fip.totalNumParameters < MAX_NUM_PARAMS);

  IgorTypeUnion retStorage = {};
  CallFunctionParameterHandler p(m_params, fip.parameterTypes,
                                 fip.numRequiredParameters);

  rc = CallFunction(&fip, (void *) p.GetValues(), &retStorage);
  ASSERT(rc == 0);

  auto functionAborted = SpinProcess();

  DebugOutput(fmt::sprintf("%s: Call finished with functionAborted=%d\r",
                           __func__, functionAborted));

  if(functionAborted)
  {
    throw RequestInterfaceException(REQ_FUNCTION_ABORTED);
  }

  auto retJSONTemplate = R"(
    {
       "errorCode" : {
         "value" : 0
       },
       "result" : {
         "type"  : "%s",
         "value" : %s
      }
    }
  )";

  auto doc = json::parse(
      fmt::sprintf(retJSONTemplate, GetTypeStringForIgorType(fip.returnType),
                   ExtractReturnStringFromUnion(&retStorage, fip.returnType)));

  // only serialize the pass-by-ref params if we have some
  if(p.HasPassByRefParameters())
  {
    auto passByRef = p.GetPassByRefArray();

    // we can have optional pass-by-ref structures which we don't support
    if(!passByRef.empty())
    {
      doc["passByReference"] = passByRef;
    }
  }

  return doc;
}
