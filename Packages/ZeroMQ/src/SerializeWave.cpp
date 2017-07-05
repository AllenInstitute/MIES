#include "ZeroMQ.h"
#include <algorithm>

namespace
{

std::string JSONQuote(std::string str)
{
  return json(str).dump();
}

TickCountInt ConvertToUnixEpochUTC(TickCountInt secs)
{
  if(secs == 0)
  {
    // wave is either a free wave or a permanent wave
    // created with Igor Pro earlier than 1.2
    return secs;
  }

  // calculate the offset including local time zone to the unix epoch
  short year       = 1970;
  short month      = 1;
  short dayOfMonth = 1;
  double offset;

  auto rc = DateToIgorDateInSeconds(1, &year, &month, &dayOfMonth, &offset);
  ASSERT(rc == 0);

  return secs - static_cast<TickCountInt>(offset);
}

TickCountInt GetModificationDate(waveHndl waveHandle)
{
  return ConvertToUnixEpochUTC(WaveModDate(waveHandle));
}

std::string GetWaveTypeString(int waveType)
{
  std::string result;

  const auto isComplex = waveType & NT_CMPLX;
  waveType &= ~NT_CMPLX;

  const auto isUnsigned = waveType & NT_UNSIGNED;
  waveType &= ~NT_UNSIGNED;

  switch(waveType)
  {
  case NT_FP32:
    result = "NT_FP32";
    break;
  case NT_FP64:
    result = "NT_FP64";
    break;
  case NT_I8:
    result = "NT_I8";
    break;
  case NT_I16:
    result = "NT_I16";
    break;
  case NT_I32:
    result = "NT_I32";
    break;
  case NT_I64:
    result = "NT_I64";
    break;
  case TEXT_WAVE_TYPE:
    result = "TEXT_WAVE_TYPE";
    break;
  case WAVE_TYPE:
    result = "WAVE_TYPE";
    break;
  case DATAFOLDER_TYPE:
    result = "DATAFOLDER_TYPE";
    break;
  default:
    ASSERT(0);
    // never reached
    return std::string();
    break;
  }

  if(isComplex)
  {
    result += " | NT_CMPLX";
  }

  if(isUnsigned)
  {
    result += " | NT_UNSIGNED";
  }

  return result;
}

template <typename T>
T *GetWaveDataPtr(waveHndl waveH)
{
  BCInt dataOffset;
  const int accessMode = kMDWaveAccessMode0;
  const int ret = MDAccessNumericWaveData(waveH, accessMode, &dataOffset);

  if(ret != 0)
  {
    throw std::runtime_error(
        fmt::sprintf("MDAccessNumericWaveData returned error %d", ret));
  }

  return reinterpret_cast<T *>(reinterpret_cast<char *>(*waveH) + dataOffset);
}

template <typename T, int withComma>
struct WriteIntoStream
{
  void operator()(fmt::MemoryWriter &writer, T val)
  {
    auto formatSpec = GetFormatString<T, withComma>()();

    writer.write(formatSpec, val);
  }
};

template <int withComma>
struct WriteIntoStream<double, withComma>
{
  void operator()(fmt::MemoryWriter &writer, double val)
  {
    auto formatSpecNumber = GetFormatString<double, withComma>()();
    auto formatSpecString = GetFormatString<char *, withComma>()();

    if(std::isnan(val) || std::isinf(val))
    {
      writer.write(formatSpecString, JSONQuote(std::to_string(val)));
    }
    else
    {
      writer.write(formatSpecNumber, val);
    }
  }
};

template <int withComma>
struct WriteIntoStream<float, withComma>
{
  void operator()(fmt::MemoryWriter &writer, float val)
  {
    auto formatSpecNumber = GetFormatString<float, withComma>()();
    auto formatSpecString = GetFormatString<char *, withComma>()();

    if(std::isnan(val) || std::isinf(val))
    {
      writer.write(formatSpecString, JSONQuote(std::to_string(val)));
    }
    else
    {
      writer.write(formatSpecNumber, val);
    }
  }
};

template <int withComma>
struct WriteIntoStream<char *, withComma>
{
  void operator()(fmt::MemoryWriter &writer, char *val)
  {
    auto formatSpec = GetFormatString<char *, withComma>()();

    writer.write(formatSpec, JSONQuote(val));
  }
};

template <int withComma>
struct WriteIntoStream<std::string, withComma>
{
  void operator()(fmt::MemoryWriter &writer, std::string val)
  {
    auto formatSpec = GetFormatString<char *, withComma>()();

    writer.write(formatSpec, JSONQuote(val));
  }
};

template <typename T>
void OutputArray(fmt::MemoryWriter &writer, T *data, CountInt dataLength)
{
  WriteIntoStream<T, 1> streamWriterWithComma;
  WriteIntoStream<T, 0> streamWriter;

  writer << "[";

  CountInt i;
  for(i = 0; i < dataLength - 1; i++)
  {
    streamWriterWithComma(writer, *(data + i));
  }

  streamWriter(writer, *(data + i));

  writer << "]";
}

template <typename T>
void ToString(fmt::MemoryWriter &writer, waveHndl waveHandle, CountInt offset)
{
  auto dataLength = WavePoints(waveHandle);

  if(dataLength == 0)
  {
    writer.write("[]");
    return;
  }

  T *data = GetWaveDataPtr<T>(waveHandle);
  data += offset;

  OutputArray(writer, data, dataLength);
}

template <>
void ToString<char *>(fmt::MemoryWriter &writer, waveHndl waveHandle,
                      CountInt /* offset */)
{
  const auto dataLength = WavePoints(waveHandle);

  if(dataLength == 0)
  {
    writer.write("[]");
    return;
  }

  Handle textHandle = WMNewHandle(0);
  ASSERT(textHandle != nullptr);
  const auto mode = 0;
  auto rc         = GetTextWaveData(waveHandle, mode, &textHandle);
  ASSERT(rc == 0);
  char *data = *textHandle;

  WriteIntoStream<char *, 1> streamWriterWithComma;
  WriteIntoStream<char *, 0> streamWriter;

  writer << "[";

  CountInt i;
  for(i = 0; i < dataLength - 1; i++)
  {
    streamWriterWithComma(writer, data);
    data += strlen(data) + 1;
  }

  streamWriter(writer, data);

  writer << "]";

  WMDisposeHandle(textHandle);
}

std::string WaveToStringImpl(int waveType, waveHndl waveHandle, CountInt offset)
{
  fmt::MemoryWriter writer;

  switch(waveType)
  {
  case NT_FP32:
    ToString<float>(writer, waveHandle, offset);
    break;
  case NT_FP64:
    ToString<double>(writer, waveHandle, offset);
    break;
  case NT_I8:
    ToString<int8_t>(writer, waveHandle, offset);
    break;
  case NT_I16:
    ToString<int16_t>(writer, waveHandle, offset);
    break;
  case NT_I32:
    ToString<int32_t>(writer, waveHandle, offset);
    break;
  case NT_I64:
    ToString<int64_t>(writer, waveHandle, offset);
    break;
  case NT_I8 | NT_UNSIGNED:
    ToString<uint8_t>(writer, waveHandle, offset);
    break;
  case NT_I16 | NT_UNSIGNED:
    ToString<uint16_t>(writer, waveHandle, offset);
    break;
  case NT_I32 | NT_UNSIGNED:
    ToString<uint32_t>(writer, waveHandle, offset);
    break;
  case NT_I64 | NT_UNSIGNED:
    ToString<uint64_t>(writer, waveHandle, offset);
    break;
  case TEXT_WAVE_TYPE:
    ToString<char *>(writer, waveHandle, offset);
    break;
  case WAVE_TYPE:
  case DATAFOLDER_TYPE:
  default:
    ASSERT(0);
    return std::string();
    break;
  }

  return writer.str();
}

std::string WaveToString(int waveType, waveHndl waveHandle)
{
  const auto isComplex = waveType & NT_CMPLX;
  waveType &= ~NT_CMPLX;

  if(!isComplex)
  {
    return WaveToStringImpl(waveType, waveHandle, 0);
  }

  auto resultTemplate = R"({
      "real"     : %s,
      "imag"     : %s
      }
   )";

  return fmt::sprintf(
      resultTemplate, WaveToStringImpl(waveType, waveHandle, 0),
      WaveToStringImpl(waveType, waveHandle, WavePoints(waveHandle)));
}

std::vector<CountInt> GetDimensionSizes(waveHndl waveHandle)
{
  int numDimensions = 0;
  std::vector<CountInt> dimensionSizes(MAX_DIMENSIONS + 1);
  auto rc =
      MDGetWaveDimensions(waveHandle, &numDimensions, dimensionSizes.data());
  ASSERT(rc == 0);

  dimensionSizes.resize(numDimensions);

  return dimensionSizes;
}

std::string DimensionSizesToString(std::vector<CountInt> dimensionSizes)
{
  if(dimensionSizes.size() == 0)
  {
    // special case an empty wave
    return "[0]";
  }

  fmt::MemoryWriter writer;
  OutputArray(writer, &dimensionSizes[0], dimensionSizes.size());

  return writer.str();
}

void AddDataFullScaleIfSet(json &doc, waveHndl waveHandle)
{
  std::vector<double> entries = {DOUBLE_NAN, DOUBLE_NAN};

  // see the documentation to MDGetWaveScaling, the order 1, 0 is correct
  auto rc = MDGetWaveScaling(waveHandle, -1, &entries[1], &entries[0]);
  ASSERT(rc == 0);

  // heuristic;
  // in Igor you would use the first "isValid" entry of the WaveInfo string
  if((entries[0] == 0.0 && entries[1] == 0.0) ||
     (std::isnan(entries[0]) && std::isnan(entries[1])))
  {
    return;
  }

  fmt::MemoryWriter writer;
  OutputArray(writer, &entries[0], entries.size());

  doc["data"]["fullScale"] = json::parse(writer.str());
}

void AddDataUnitIfSet(json &doc, waveHndl waveHandle)
{
  char unit[MAX_UNIT_CHARS + 1];

  auto rc = MDGetWaveUnits(waveHandle, -1, unit);
  ASSERT(rc == 0);

  if(strlen(unit) > 0)
  {
    doc["data"]["unit"] = unit;
  }
}

void AddDimensionScalingIfSet(json &doc, waveHndl waveHandle,
                              std::vector<CountInt> dimSizes)
{
  const auto numDimensions  = dimSizes.size();
  auto differentFromDefault = false;

  std::vector<double> offset(numDimensions), delta(numDimensions);

  for(size_t i = 0; i < numDimensions; i++)
  {
    auto rc = MDGetWaveScaling(waveHandle, static_cast<int>(i), &delta[i],
                               &offset[i]);
    ASSERT(rc == 0);

    differentFromDefault |= (offset[i] != 0.0 || delta[i] != 1.0);
  }

  if(differentFromDefault)
  {
    fmt::MemoryWriter writer;

    OutputArray(writer, &offset[0], offset.size());
    doc["dimension"]["offset"] = json::parse(writer.str());

    writer.clear();

    OutputArray(writer, &delta[0], delta.size());
    doc["dimension"]["delta"] = json::parse(writer.str());
  }
}

void AddDimensionUnitsIfSet(json &doc, waveHndl waveHandle,
                            std::vector<CountInt> dimSizes)
{
  const auto numDimensions  = dimSizes.size();
  auto differentFromDefault = false;

  std::vector<std::string> units(numDimensions);

  for(size_t i = 0; i < numDimensions; i++)
  {
    char unit[MAX_UNIT_CHARS + 1];
    auto rc = MDGetWaveUnits(waveHandle, static_cast<int>(i), unit);
    ASSERT(rc == 0);

    if(strlen(unit) > 0)
    {
      units[i]             = unit;
      differentFromDefault = true;
    }
  }

  if(differentFromDefault)
  {
    fmt::MemoryWriter writer;

    OutputArray(writer, &units[0], units.size());
    doc["dimension"]["unit"] = json::parse(writer.str());
  }
}

void AddDimensionLabelsFullIfSet(json &doc, waveHndl waveHandle,
                                 std::vector<CountInt> dimSizes)
{
  const auto numDimensions  = dimSizes.size();
  auto differentFromDefault = false;

  // label for the full dimension
  std::vector<std::string> labels(numDimensions);

  for(size_t i = 0; i < numDimensions; i++)
  {
    char label[MAX_DIM_LABEL_BYTES + 1];
    auto rc = MDGetDimensionLabel(waveHandle, static_cast<int>(i), -1, label);
    ASSERT(rc == 0);

    if(strlen(label) > 0)
    {
      labels[i]            = label;
      differentFromDefault = true;
    }
  }

  if(differentFromDefault)
  {
    fmt::MemoryWriter writer;

    OutputArray(writer, &labels[0], labels.size());
    doc["dimension"]["label"]["full"] = json::parse(writer.str());
  }
}

void AddDimensionLabelsEachIfSet(json &doc, waveHndl waveHandle,
                                 std::vector<CountInt> dimSizes)
{
  const auto numDimensions  = dimSizes.size();
  auto differentFromDefault = false;
  CountInt k                = 0;

  // label for the each dimension index
  // serialized here with column-major order
  std::vector<std::string> labels(std::accumulate(
      dimSizes.begin(), dimSizes.end(), static_cast<CountInt>(0)));

  for(size_t i = 0; i < numDimensions; i++)
  {
    for(CountInt j = 0; j < dimSizes[i]; j++)
    {
      char label[MAX_DIM_LABEL_BYTES + 1];
      auto rc = MDGetDimensionLabel(waveHandle, static_cast<int>(i), j, label);
      ASSERT(rc == 0);

      if(strlen(label) > 0)
      {
        differentFromDefault = true;
        labels[k++]          = label;
      }
    }
  }

  if(differentFromDefault)
  {
    fmt::MemoryWriter writer;

    OutputArray(writer, &labels[0], labels.size());
    doc["dimension"]["label"]["each"] = json::parse(writer.str());
  }
}

void AddWaveNoteIfSet(json &doc, waveHndl waveHandle)
{
  auto handle = WaveNoteCopy(waveHandle);

  if(handle == nullptr)
  {
    return;
  }

  doc["note"] = json(GetStringFromHandle(handle));
  WMDisposeHandle(handle);
}

} // anonymous namespace

std::string SerializeWave(waveHndl waveHandle)
{
  if(waveHandle == nullptr)
  {
    return "null";
  }

  const auto waveType       = WaveType(waveHandle);
  const auto modDate        = GetModificationDate(waveHandle);
  const auto type           = GetWaveTypeString(waveType);
  const auto rawData        = WaveToString(waveType, waveHandle);
  const auto dimSizes       = GetDimensionSizes(waveHandle);
  const auto dimSizesString = DimensionSizesToString(dimSizes);

  DebugOutput(fmt::sprintf(
      "%s: waveType=%d, modDate=%d, type=%s, dimSizes=%s, rawData=%.255s\r",
      __func__, waveType, modDate, type, dimSizesString, rawData));

  json doc;
  doc["type"]                 = type;
  doc["date"]["modification"] = modDate;
  doc["data"]["raw"]          = json::parse(rawData);
  doc["dimension"]["size"]    = json::parse(dimSizesString);

  AddDataUnitIfSet(doc, waveHandle);
  AddDataFullScaleIfSet(doc, waveHandle);
  AddDimensionScalingIfSet(doc, waveHandle, dimSizes);
  AddDimensionUnitsIfSet(doc, waveHandle, dimSizes);
  AddDimensionLabelsEachIfSet(doc, waveHandle, dimSizes);
  AddDimensionLabelsFullIfSet(doc, waveHandle, dimSizes);
  AddWaveNoteIfSet(doc, waveHandle);

  return doc.dump(4);
}
