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

static inline int
isSurrogate(unsigned int codePoint)
{
    return 0xD800 <= codePoint && codePoint <= 0xDFFF;
}

static inline int
isSurrogateLow(unsigned int codePoint)
{
    return 0xDC00 <= codePoint && codePoint <= 0xDFFF;
}

static inline int
isSurrogateHigh(unsigned int codePoint)
{
    return 0xD800 <= codePoint && codePoint <= 0xDBFF;
}

const char *
sqUTF8ToUTF32Iterate(const char *string, int *dest)
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

extern const unsigned short *
sqUTF16ToUTF32Iterate(const unsigned short *string, int *dest)
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

extern unsigned short *
sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src)
{
    int codePoint;
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

static size_t
sqEncodeUTF8CodePoint(char *buffer, size_t bufferSize, int codePoint)
{
    if(codePoint < 128)
    {
        if(bufferSize >= 1)
            *buffer = (char)codePoint;
        return 1;
    }

    /* We first need to count the required number of characters */
    size_t encodedSize = 1;
    int remainingFirstBits = 6;
    int testCodePoint = codePoint;
    int codePointBits = 0;
    while(testCodePoint >= (1 << remainingFirstBits))
    {
        --remainingFirstBits;
        ++encodedSize;
        testCodePoint >>= 6;
        codePointBits += 6;
    }

    /* Only encode if there is enough space. */
    if(bufferSize >= encodedSize)
    {
        /* Encode the first byte. */
        unsigned int bitIndex = codePointBits;
        unsigned int payloadMask = (1<<remainingFirstBits) - 1;
        unsigned int payload = (codePoint >> bitIndex) & payloadMask;
        *buffer++ = ((~payloadMask) ^ (payloadMask + 1)) | payload;

        /* Encode the remaining elements*/
        payloadMask = 63;
        for(int i = 1; i < encodedSize; ++i)
        {
            bitIndex -= 6;
            payload = (codePoint >> bitIndex) & payloadMask;
            *buffer++ = 0x80 | payload;
        }
    }

    return encodedSize;
}

extern char *
sqUTF16ToUTF8Copy(char *dest, size_t destSize, const unsigned short *src)
{
    char *originalDestination = dest;
    int codePoint;

    if(!src)
    {
        *dest = 0;
        return dest;
    }

    while (*src && destSize > 1)
    {
        src = sqUTF16ToUTF32Iterate(src, &codePoint);
        size_t encodedSize = sqEncodeUTF8CodePoint(dest, destSize - 1, codePoint);
        if(destSize > encodedSize)
        {
            destSize -= encodedSize;
            dest += encodedSize;
        }
    }

    *dest = 0;
    return originalDestination;
}

extern size_t
sqUTF16ToUTF8RequiredSize(const unsigned short *src)
{
    int codePoint;
    size_t requiredSize = 1; /* Null terminator */
    if(!src)
        return requiredSize;

    while (*src)
    {
        src = sqUTF16ToUTF32Iterate(src, &codePoint);
        requiredSize += sqEncodeUTF8CodePoint(NULL, 0, codePoint);
    }

    return requiredSize;
}

unsigned short *
sqUTF8ToUTF16New(const char *string)
{
    unsigned short *result;
    size_t stringLength;

    stringLength = strlen(string);
    result = (unsigned short*)calloc(stringLength + 1, sizeof(unsigned short));
    sqUTF8ToUTF16Copy(result, stringLength + 1, string);
    return result;
}

static inline size_t
wideStringLength(const wchar_t *wstring)
{
    size_t result = 0;
    while(*wstring)
    {
        ++wstring;
        ++result;
    }

    return result;
}

extern char *
sqUTF16ToUTF8New(const unsigned short *string)
{
    char *result;

    size_t bufferSize = sqUTF16ToUTF8RequiredSize(string);
    result = (char*)calloc(bufferSize, 1); /* TODO: Count for the actually required buffer size. */
    sqUTF16ToUTF8Copy(result, bufferSize, string);
    return result;
}
