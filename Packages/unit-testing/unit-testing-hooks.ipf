#pragma rtGlobals=3
#pragma version=1.06
#pragma TextEncoding="UTF-8"

// Licensed under 3-Clause BSD, see License.txt

// These functions are included for compatibility only
// and have no functionality. Do NOT call this functions in future
// test setups to extend a test run. The functions may be removed in a later version.

// Instead:
// To insert user code into a test run user the _OVERRIDE functions
// such as TEST_BEGIN_OVERRIDE(name)
// See documentation refman.pdf for details.

Function TEST_BEGIN(name)
	string name
End

Function TEST_END(name)
	string name
End

Function TEST_SUITE_BEGIN(testSuite)
	string testSuite
End

Function TEST_SUITE_END(testSuite)
	string testSuite
End

Function TEST_CASE_BEGIN(testCase)
	string testCase
End

Function TEST_CASE_END(testCase)
	string testCase
End
