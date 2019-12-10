#ifndef PHAROVM_ERROR_CODES_H
#define PHAROVM_ERROR_CODES_H

#pragma once

#include "pharo.h" // For EXPORT FIXME: it should be possible to avoid including all of that.

typedef enum VMErrorCode_
{
    VM_SUCCESS = 0,
    VM_ERROR = -1,
    VM_ERROR_OUT_OF_MEMORY = -2,
    VM_ERROR_NULL_POINTER = -3,
    VM_ERROR_EXIT_WITH_SUCCESS = -4,
    VM_ERROR_INVALID_PARAMETER = -5,
    VM_ERROR_INVALID_PARAMETER_VALUE = -6
} VMErrorCode;

EXPORT(const char*) vm_error_code_to_string(VMErrorCode errorCode);

#endif //PHAROVM_ERROR_CODES_H
