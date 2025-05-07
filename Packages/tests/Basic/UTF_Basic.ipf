#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=Basic

#include "UTF_Basic_includes"

Function TEST_BEGIN_OVERRIDE(string name)

	TestBeginCommon()
End

Function TEST_END_OVERRIDE(string name)

	TestEndCommon()
End

Function TEST_CASE_BEGIN_OVERRIDE(string name)

	TestCaseBeginCommon(name)
End

Function TEST_CASE_END_OVERRIDE(string testcase)

	TestCaseEndCommon(testcase)
End
