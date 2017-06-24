#include "CallFunctionParameterHandler.h"
#include "ZeroMQ.h"

CallFunctionParameterHandler::CallFunctionParameterHandler(
    StringVector params, int parameterTypes[MAX_NUM_PARAMS], int numParams)
    : m_hasPassByRefParams(false)
{
  ASSERT(numParams == (int) params.size());

  if(numParams == 0)
  {
    return;
  }

  m_paramSizesInBytes.resize(numParams);
  m_paramTypes.resize(numParams);
  std::copy(&parameterTypes[0], &parameterTypes[0] + numParams,
            m_paramTypes.begin());

  size_t arraySizeInBytes = 0;
  for(int i = 0; i < numParams; i++)
  {
    m_hasPassByRefParams |= (m_paramTypes[i] & FV_REF_TYPE) == FV_REF_TYPE;

    const auto type = m_paramTypes[i] & ~FV_REF_TYPE;

    switch(type)
    {
    case NT_FP64:
      m_paramSizesInBytes[i] = sizeof(double);
      break;
    case HSTRING_TYPE:
      m_paramSizesInBytes[i] = sizeof(Handle);
      break;
    case DATAFOLDER_TYPE:
      m_paramSizesInBytes[i] = sizeof(DataFolderHandle);
      break;
    default:
      ASSERT(0);
      break;
    }

    arraySizeInBytes += m_paramSizesInBytes[i];
  }

  unsigned char *dest = GetValues();
  for(int i = 0; i < numParams; i++)
  {
    const auto type = m_paramTypes[i] & ~FV_REF_TYPE;

    IgorTypeUnion u;

    switch(type)
    {
    case NT_FP64:
      u.variable = ConvertStringToDouble(params[i]);
      break;
    case HSTRING_TYPE:
      u.stringHandle = WMNewHandle(params[i].size());
      ASSERT(u.stringHandle != nullptr);
      memcpy(*u.stringHandle, params[i].c_str(), params[i].size());
      break;
    case DATAFOLDER_TYPE:
      u.dataFolderHandle = DeSerializeDataFolder(params[i].c_str());
      break;
    default:
      ASSERT(0);
      break;
    }

    // we write one parameter after another into our array
    // we can not use IgorTypeUnion here as the padding on 32bit
    // (void* is 4, but a double 8) breaks the reading code in CallFunction.
    memcpy(dest, &u, m_paramSizesInBytes[i]);
    dest += m_paramSizesInBytes[i];
  }
}

json CallFunctionParameterHandler::GetPassByRefArray()
{
  unsigned char *src = GetValues();
  IgorTypeUnion u;

  std::vector<std::string> elems;
  elems.reserve(m_paramTypes.size());

  for(size_t i = 0; i < m_paramTypes.size(); i++)
  {
    switch(m_paramTypes[i])
    {
    case NT_FP64 | FV_REF_TYPE:
      memcpy(&u, src, m_paramSizesInBytes[i]);
      elems.push_back(To_stringHighRes(u.variable));
      break;
    case HSTRING_TYPE | FV_REF_TYPE:
      memcpy(&u, src, m_paramSizesInBytes[i]);
      elems.push_back(GetStringFromHandle(u.stringHandle));
      break;
    }

    src += m_paramSizesInBytes[i];
  }

  return json(elems);
}

bool CallFunctionParameterHandler::HasPassByRefParameters()
{
  return m_hasPassByRefParams;
}

CallFunctionParameterHandler::~CallFunctionParameterHandler()
{
  unsigned char *src = GetValues();
  IgorTypeUnion u;

  for(size_t i = 0; i < m_paramTypes.size(); i++)
  {
    switch(m_paramTypes[i])
    {
    case HSTRING_TYPE | FV_REF_TYPE:
      memcpy(&u, src, m_paramSizesInBytes[i]);
      if(u.stringHandle != nullptr)
      {
        WMDisposeHandle(u.stringHandle);
      }
      break;
    }

    src += m_paramSizesInBytes[i];
  }
}
