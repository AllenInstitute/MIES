#pragma once

#include "CustomExceptions.h"

class RequestInterfaceException : public IgorException
{
public:
  explicit RequestInterfaceException(int errorCode);
};
