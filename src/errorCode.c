#include "errorCode.h"

EXPORT(const char*)
vm_error_code_to_string(VMErrorCode errorCode)
{
    switch(errorCode)
    {
    case VM_SUCCESS: return "sucess";
    case VM_ERROR_OUT_OF_MEMORY: return "out of memory.";
    case VM_ERROR_NULL_POINTER: return "null pointer.";
    case VM_ERROR_EXIT_WITH_SUCCESS: return "exit with success.";
    case VM_ERROR_INVALID_PARAMETER: return "invalid parameter.";
    case VM_ERROR_INVALID_PARAMETER_VALUE: return "null parameter value.";
    case VM_ERROR:
    default:
        return "generic error";
    }
}
