#pragma once

#include <ctime>
#include <cerrno>
#include <cstdint>
#include <cstring>
#include <cmath>
#include <sstream>
#include <iterator>
#include <algorithm>
#include <memory>
#include <string>
#include <vector>
#include <functional>
#include <exception>
#include <thread>
#include <numeric>
#include <mutex>

#include "zmq.h"

#ifdef __GNUC__
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
#endif

#include "XOPStandardHeaders.h" // Include ANSI headers, Mac headers, IgorXOP.h, XOP.h and XOPSupport.h
#ifdef __GNUC__
#pragma GCC diagnostic pop
#endif

// Usign std::min/max
#undef min
#undef max

#include "json/json.hpp"
using json = nlohmann::basic_json<>;

class CallFunctionOperation;
using CallFunctionOperationPtr = std::shared_ptr<CallFunctionOperation>;

class RequestInterface;
using RequestInterfacePtr = std::shared_ptr<RequestInterface>;

using StringVector = std::vector<std::string>;

using LockGuard = std::lock_guard<std::recursive_mutex>;

#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable : 4018)
#endif
#include "fmt/ostream.h"
#include "fmt/format.h"
#include "fmt/printf.h"
#ifdef _MSC_VER
#pragma warning(pop)
#endif

#include "functions.h"
#include "GlobalData.h"
#include "CustomExceptions.h"
#include "RequestInterfaceException.h"
#include "HelperFunctions.h"
#include "ConcurrentXOPNotice.h"
#include "SocketWithMutex.h"
#include "Errors.h"

// see also FunctionInfo XOPSupport function
const int MAX_NUM_PARAMS        = 100;
const std::string MESSAGEID_KEY = "messageID";

/* Prototypes */
HOST_IMPORT int XOPMain(IORecHandle ioRecHandle);
