#include "ZeroMQ.h"
#include "RequestInterface.h"
#include "CallFunctionOperation.h"
#include <string>
#include "SerializeWave.h"

// string zeromq_test_serializeWave(WAVE wv)
extern "C" int zeromq_test_serializeWave(zeromq_test_serializeWaveParams *p)
{
  BEGIN_OUTER_CATCH

  DebugOutput(fmt::sprintf("%s\r", __func__));

  auto str = SerializeWave(p->wv);

  DebugOutput(fmt::sprintf("%s: output=%.255s\r", __func__, str));

  auto len  = str.size();
  p->result = WMNewHandle(len);
  ASSERT(p->result != nullptr);
  memcpy(*(p->result), str.c_str(), len);

  END_OUTER_CATCH
}
