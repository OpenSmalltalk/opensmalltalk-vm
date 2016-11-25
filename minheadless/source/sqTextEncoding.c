#include "sq.h"

const char *sqUTF8ToUTF32Iterate(const char *string, int *dest)
{
    unsigned int first;
    unsigned int sequenceSize;
    unsigned int i;
    unsigned int byte;
    *dest = 0;

    first = (*string) & 0xFF;
    if(first == 0)
        return string;

    /* Single byte case */
    ++string;
    if(first <= 127)
    {
        *dest = first;
        return string;
    }

    /* Count the size of the character */
    sequenceSize = 0;
    while(first & 0x80)
    {
        first = (first << 1) & 0xFF;
        ++sequenceSize;
    }

    first >>= sequenceSize;

    /* Decode the full code point. */
    *dest = first;
    --sequenceSize;

    for(i = 0; i < sequenceSize; ++i)
    {
        /* Fetch the next byte */
        byte = *string;
        if(!byte)
            return string;
        ++string;

        /* Append the byte data */
        *dest = (*dest << 6) | (byte & 63);
    }

    return string;
}

extern unsigned short *sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src)
{
    unsigned short *originalDestination = dest;

    /* TODO: Implement this properly. */
    while (*src && destSize > 1)
    {
        *dest++ = *src++;
        --destSize;
    }

    *dest = 0;
    return originalDestination;
}

extern unsigned short *sqUTF8toUTF16New(const char *string)
{
    unsigned short *result;
    size_t stringLength;

    stringLength = strlen(string);
    result = (unsigned short*)calloc(stringLength + 1, sizeof(unsigned short));
    sqUTF8ToUTF16Copy(result, stringLength + 1, string);
    return result;
}
