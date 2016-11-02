#pragma once

#include <vector>

#pragma pack(2) // All structures passed to Igor are two-byte aligned.
union IgorTypeUnion {
  waveHndl waveHandle;
  double variable;
  Handle stringHandle;
  DataFolderHandle dataFolderHandle;
};
#pragma pack()

using IgorTypeUnionVector = std::vector<IgorTypeUnion>;
