#pragma once

#include "ZeroMQ.h"
#include "IgorTypeUnion.h"

class CallFunctionParameterHandler
{
public:
  CallFunctionParameterHandler(StringVector params,
                               int parameterTypes[MAX_NUM_PARAMS],
                               int numParams);
  ~CallFunctionParameterHandler();

  unsigned char *GetValues()
  {
    return &m_values[0];
  }

  bool HasPassByRefParameters();

  // Return a jsons style array for the pass-by-reference parameters
  json GetPassByRefArray();

private:
  unsigned char m_values[MAX_NUM_PARAMS * sizeof(double)];
  std::vector<int> m_paramTypes;
  std::vector<CountInt> m_paramSizesInBytes;
  bool m_hasPassByRefParams;
};
