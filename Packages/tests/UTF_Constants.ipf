#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=TestingConstants

#ifdef TESTS_WITH_SUTTER_HARDWARE
Constant PSQ_TEST_HEADSTAGE = 0
#else
Constant PSQ_TEST_HEADSTAGE = 2
#endif

StrConstant ZSTD_SUFFIX = ".zst"

Constant TP_DURATION_S = 5

Constant PSQ_TEST_VERY_LARGE_FREQUENCY = 1e350
