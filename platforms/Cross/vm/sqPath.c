/* sqPath.c -- Path manipulation functions
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

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#elif defined(__unix__) || defined(__MACH__) || defined(__APPLE__)
#include <unistd.h>
#else
#define getcwd(target, targetSize) strcpy(target, ".")
#endif
#include <string.h>

#include "sqPath.h"
#include "sqTextEncoding.h"

void sqGetCurrentWorkingDir(char *target, size_t targetSize)
{
#ifdef _WIN32
    unsigned short *tempBuffer = (unsigned short*)calloc(MAX_PATH + 1, sizeof(unsigned short));
    GetCurrentDirectoryW(MAX_PATH + 1, tempBuffer);
    sqUTF16ToUTF8Copy(target, targetSize, tempBuffer);
    free(tempBuffer);
#else
    getcwd(target, targetSize);
#endif
}

int sqIsAbsolutePath(const char *path)
{
#ifdef _WIN32
    return path && (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return path && (*path == '/');
#endif
}

void sqPathMakeAbsolute(char *target, size_t targetSize, const char *src)
{
    if (sqIsAbsolutePath(src))
    {
        strcpy(target, src);
    }
    else
    {
        sqGetCurrentWorkingDir(target, targetSize);
        /* TODO: Make a more secure copy than strcat*/
#ifdef _WIN32
        strcat(target, "\\");
        if (src[0] == '.' && (src[1] == '/' || src[1] == '\\'))
            strcat(target, src + 2);
        else
            strcat(target, src);
#else
        strcat(target, "/");
        if(src[0] == '.' && src[1] == '/')
            strcat(target, src + 2);
        else
            strcat(target, src);
#endif
    }
}

void sqPathExtractDirname(char *target, size_t targetSize, const char *src)
{
    size_t copySize;
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif
    copySize = targetSize;
    if (lastSeparator && lastSeparator - src + 1 < copySize)
        copySize = lastSeparator - src + 1;
    strncpy(target, src, copySize);
}

void sqPathExtractBaseName(char *target, size_t targetSize, const char *src)
{
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if (lastSeparator)
        strncpy(target, lastSeparator, targetSize);
    else
        strcpy(target, "");
}

#ifdef _WIN32
# define SEPARATOR_STRING "\\"
# define SEPARATOR_CHAR '\\'
#else
# define SEPARATOR_STRING "/"
# define SEPARATOR_CHAR '/'
#endif
void sqPathJoin(char *target, size_t targetSize, const char *first, const char *second)
{
    strcpy(target, first);
    if(first[strlen(first)-1] != SEPARATOR_CHAR) {
        strcat(target, SEPARATOR_STRING);
    }
    strcat(target, second);
}
