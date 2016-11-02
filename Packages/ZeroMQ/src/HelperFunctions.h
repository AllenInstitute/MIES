#pragma once

#include <sstream>
#include <iomanip>

/// @brief Converts a double value to a specified integer type.
///
/// Returns an error if:
/// - The value is NaN of +/- inf
/// - The value lies outside the range of the integer representation.
///
/// The value is truncated towards zero
/// That is:
/// - Positive numbers are rounded down
/// - Negative numbers are rounded up
///
/// If the value is NaN, zero is returned.
///
/// @tparam	T	integer type to convert to.
/// @param	val	value to convert
/// @return	converted value
template <typename T>
T lockToIntegerRange(double val)
{
  // If value is NaN or inf, return an appropriate error.
  if(std::isnan(val) || std::isinf(val))
  {
    throw IgorException(kDoesNotSupportNaNorINF);
  }

  // If value lies outside range of integer type, return an error.
  if(val > (double) std::numeric_limits<T>::max() ||
     val < (double) std::numeric_limits<T>::min())
  {
    throw IgorException(kParameterOutOfRange);
  }

  // Truncate towards zero.
  // 10.1 becomes 10
  // -10.1 becomes -10.
  if(val > 0)
  {
    val = std::floor(val);
  }
  if(val < 0)
  {
    val = std::ceil(val);
  }

  return static_cast<T>(val);
}

template <>
bool lockToIntegerRange<bool>(double val);

/// @brief Return the size in bytes of the given Igor Pro wave types
///
/// The returned size is zero for non-numeric wave types
std::size_t GetWaveElementSize(int dataType);

/// @brief Set all elements of the given wave to zero
///
/// Does nothing for non-numeric waves
void WaveClear(waveHndl wv);

/// @brief Convert Igor string into std::string
///
/// If the string handle is null, the empty string is returned.
///
/// @param	strHandle	handle to Igor string
/// @return	std::string containing the same data
std::string GetStringFromHandle(Handle strHandle);

void SetDimensionLabels(waveHndl h, int Dimension,
                        const std::vector<std::string> &dimLabels);

void DebugOutput(std::string str);

void ApplyFlags(double flags);

namespace ZeroMQ_SET_FLAGS
{

enum ZeroMQ_SET_FLAGS
{
  DEFAULT              = 1,
  DEBUG                = 2,
  IPV6                 = 4,
  NO_RECV_BUSY_WAITING = 8
};
}

std::string GetLastEndPoint(void *s);
void ToggleIPV6Support(bool enable);

template <typename T, int withComma>
struct GetFormatString
{
  std::string operator()()
  {
    if(withComma)
    {
      return "{}, ";
    }

    return "{}";
  }
};

template <int withComma>
struct GetFormatString<double, withComma>
{
  std::string operator()()
  {
    static_assert(std::numeric_limits<double>::digits10 == 15,
                  "Unexpected double precision");

    if(withComma)
    {
      return "{:.15g}, ";
    }

    return "{:.15g}";
  }
};

template <typename T>
std::string To_stringHighRes(const T val)
{
  std::string fmt = GetFormatString<T, 0>()();

  return fmt::format(fmt, val);
}

double ConvertStringToDouble(std::string str);
std::string CallIgorFunctionFromMessage(std::string msg);

int ZeroMQClientSend(std::string payload);
int ZeroMQServerSend(std::string identity, std::string payload);
int ZeroMQClientReceive(zmq_msg_t *payloadMsg);
int ZeroMQServerReceive(zmq_msg_t *identityMsg, zmq_msg_t *payloadMsg);

std::string SerializeDataFolder(DataFolderHandle dataFolderHandle);
DataFolderHandle DeSerializeDataFolder(std::string path);

std::string CreateStringFromZMsg(zmq_msg_t *msg);

void InitHandle(Handle *handle, size_t size);
void WriteZMsgIntoHandle(Handle *handle, zmq_msg_t *msg);
