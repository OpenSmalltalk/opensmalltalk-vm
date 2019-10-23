#ifndef PHAROVM_PARAMETER_VECTOR_H
#define PHAROVM_PARAMETER_VECTOR_H

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include "errorCode.h"
#include <stdbool.h> // For bool
#include <stdint.h>

/**
 * Parameter vector.
 * I am used to hold an array of arguments.
 */
typedef struct VMParameterVector_
{
	uint32_t count;
	const char ** parameters;
} VMParameterVector;

EXPORT(VMErrorCode) vm_parameter_vector_destroy(VMParameterVector *vector);
EXPORT(VMErrorCode) vm_parameter_vector_insert_from(VMParameterVector *vector, uint32_t count, const char **arguments);
EXPORT(bool) vm_parameter_vector_has_element(VMParameterVector *vector, const char *parameter);

#ifdef __cplusplus
}
#endif

#endif //PHAROVM_PARAMETER_VECTOR_H
