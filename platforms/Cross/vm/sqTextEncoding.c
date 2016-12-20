/* sqTextEncoding.c -- UTF8, UTF16 and UTF32 text encoding conversion functions
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */

#include "sq.h"
#include "sqTextEncoding.h"

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

extern const unsigned short *sqUTF16ToUTF32Iterate(const unsigned short *string, int *dest)
{
    unsigned int high;
    unsigned int low;
    *dest = 0;
    if(!*string)
        return string;

    while((high = *string) != 0)
    {
        ++string;
        if(high < 0xD800 || 0xE000 <= high)
        {
            /* Single byte*/
            *dest = high;
            break;
        }
        else if(high < 0xDC00)
        {
            /* Low surrogate*/
            low = *string;
            if(!low)
                break;

            /* Validate the low surrogate */
            ++string;
            if(0xDC00 <= low && low < 0xE000)
            {
                *dest = (high - 0xD800) << 10 | (low - 0xDC00);
            }

            /* Invalid character. Continue*/
        }
        else
        {
            /* Invalid low surrogate without preceding high surrogate. Ignore it*/
        }
    }

    return string;
}

extern unsigned short *sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src)
{
    unsigned int codePoint;
    const char *pos;
    unsigned short *originalDestination = dest;

    if(!src)
        return 0;

    /* Iterate through the code points present in the UTF-8 string */
    pos = src;
    while(*pos)
    {
        pos = sqUTF8ToUTF32Iterate(pos, &codePoint);
        if(destSize <= 1 || !codePoint)
            break;
        
        /* printf("CodePoint: %d\n", codePoint); */
        if(codePoint >= 0x10000)
        {
            /* Surrogate high - Surrogate low - Null terminator*/
            if(destSize < 3)
                break;

            /* Surrogate high */
            *dest = (codePoint >> 10) + 0xD800;
            ++dest; --destSize;

            /* Surrogate low */
            *dest = (codePoint & 1023) + 0xDC00;
            ++dest; --destSize;
        }
        else
        {
            /* Just pass the code point. */
            *dest = codePoint;
            ++dest; --destSize;
        }
    }
    *dest = 0;

    return originalDestination;
}

extern char *sqUTF16ToUTF8Copy(char *dest, size_t destSize, const unsigned short *src)
{
    char *originalDestination = dest;

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
