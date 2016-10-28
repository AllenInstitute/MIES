#include "ZeroMQ.h"

// variable zeromq_set(variable flags)
extern "C" int zeromq_set(zeromq_setParams *p)
{
  BEGIN_OUTER_CATCH

  DebugOutput(fmt::sprintf("%s: flags=%g\r", __func__, p->flags));
  ApplyFlags(p->flags);

  END_OUTER_CATCH
}
