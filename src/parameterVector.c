#include "parameterVector.h"
#include <stdlib.h>

VMErrorCode
vm_parameter_vector_destroy(VMParameterVector *vector)
{
	if(!vector) return VM_ERROR_NULL_POINTER;

	free(vector->parameters);
	vector->parameters = NULL;
	vector->count = 0;
	return VM_SUCCESS;
}

VMErrorCode
vm_parameter_vector_insert_from(VMParameterVector *vector, uint32_t count, const char **elements)
{
	if(!vector) return VM_ERROR_NULL_POINTER;

	uint32_t newVectorCount = vector->count + count;
	// Add an addition NULL element, for execv and family.
	const char **newVectorData = (const char **)calloc(newVectorCount + 1, sizeof(const char *));
	if(!newVectorData)
    {
		return VM_ERROR_OUT_OF_MEMORY;
	}

	// Copy the old vector parameters.
	for(uint32_t i = 0; i < vector->count; ++i)
    {
		newVectorData[i] = vector->parameters[i];
    }

	// Copy the new vector parameters.
	for(uint32_t i = 0; i < count; ++i)
    {
		newVectorData[vector->count + i] = elements[i];
    }

	// Free the old vector parameters
	free(vector->parameters); // Free of NULL is a no-op.
	vector->count = newVectorCount;
	vector->parameters = newVectorData;

	return VM_SUCCESS;
}

bool
vm_parameter_vector_has_element(VMParameterVector *vector, const char *parameter)
{
	if(!vector) return false;

	for(uint32_t i = 0; i < vector->count; ++i)
	{
		if(!strcmp(vector->parameters[i], parameter))
		{
			return true;
		}
	}

	return false;
}
