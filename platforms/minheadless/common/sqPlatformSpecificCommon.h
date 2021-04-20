/* sqPlatformSpecificCommon.h -- platform-specific modifications to sq.h
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Minimalistic Headless Squeak.
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

#ifndef _SQ_PLATFORM_SPECIFIC_COMMON_H
#define _SQ_PLATFORM_SPECIFIC_COMMON_H

#include "sqPath.h"
#include "sqTextEncoding.h"

/**
 * Printing and reporting functions.
 * In some platforms, such as Windows, stdout, stderr and stdin are not always usable
 */
extern void sqMessagePrintf(const char *format, ...);
extern void sqWarnPrintf(const char *format, ...);
extern void sqErrorPrintf(const char *format, ...);
extern void sqFatalErrorPrintf(const char *format, ...);
extern void sqFatalErrorPrintfNoExit(const char *format, ...);
#ifndef error
extern void sqError(const char *errorMessage);
#define error(x) sqError(x)
#endif



/*
#define messagePrintf sqMessagePrintf
#define warnPrintf sqWarnPrintf
#define errorPrintf sqErrorPrintf
*/

#define messagePrintf printf
#define warnPrintf printf
#define errorPrintf printf

/* Function used by the Squeak security plugin. In a headless VM, do not create a message box. */
extern int sqAskSecurityYesNoQuestion(const char *question);

extern const char *sqGetCurrentImagePath(void);

/* Stack trace dumping */
typedef int (*sqFunctionThatCouldCrash)(void *userdata);
extern int sqExecuteFunctionWithCrashExceptionCatching(sqFunctionThatCouldCrash function, void *userdata);

#endif /* _SQ_PLATFORM_SPECIFIC_COMMON_H */
