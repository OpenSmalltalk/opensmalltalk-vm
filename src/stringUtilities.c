#include "stringUtilities.h"

void
vm_string_append_into(char *dest, const char *source, size_t destBufferSize)
{
    size_t destSize = strlen(dest);
    size_t destIndex = destSize;

    for(destIndex = destSize; (destIndex < destBufferSize - 1) && (*source != 0); ++destIndex)
        dest[destIndex] = *(source++);
    dest[destIndex] = 0;
}
