#pragma once

// clang-format off
// XOP error codes
#define OLD_IGOR                   1 + FIRST_XOP_ERR
#define UNHANDLED_CPP_EXCEPTION    2 + FIRST_XOP_ERR
#define UNKNOWN_SET_FLAG           3 + FIRST_XOP_ERR
#define INTERNAL_ERROR             4 + FIRST_XOP_ERR
#define INVALID_ARG                5 + FIRST_XOP_ERR
#define HANDLER_ALREADY_RUNNING    6 + FIRST_XOP_ERR
#define HANDLER_NO_CONNECTION      7 + FIRST_XOP_ERR
#define MISSING_PROCEDURE_FILES    8 + FIRST_XOP_ERR
#define INVALID_MESSAGE_FORMAT     9 + FIRST_XOP_ERR

// non-XOP error codes

/// @name Error codes for the request JSON interface
/// @{
#define REQ_SUCCESS                    0
#define REQ_UNKNOWN_ERROR              1
#define REQ_INVALID_JSON_OBJECT        3
#define REQ_INVALID_VERSION            4
#define REQ_INVALID_OPERATION          5
#define REQ_INVALID_OPERATION_FORMAT   6
#define REQ_INVALID_MESSAGEID          7
#define REQ_OUT_OF_MEMORY              8
/// @name Error codes for the CallFunction class
/// @{
#define REQ_PROC_NOT_COMPILED        100
#define REQ_NON_EXISTING_FUNCTION    101
#define REQ_TOO_FEW_FUNCTION_PARAMS  102
#define REQ_TOO_MANY_FUNCTION_PARAMS 103
#define REQ_UNSUPPORTED_FUNC_SIG     104
#define REQ_UNSUPPORTED_FUNC_RET     105
#define REQ_INVALID_PARAM_FORMAT     106
#define REQ_FUNCTION_ABORTED         107
/// @}
/// @}
// clang-format on
