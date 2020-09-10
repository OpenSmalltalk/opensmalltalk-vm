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

#ifndef SQ_TEXT_ENCODING_H
#define SQ_TEXT_ENCODING_H

/* Text encoding conversions. */
extern const char *sqUTF8ToUTF32Iterate(const char *string, int *dest);
extern const unsigned short *sqUTF16ToUTF32Iterate(const unsigned short *string, int *dest);
extern unsigned short *sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src);
extern char *sqUTF16ToUTF8Copy(char *dest, size_t destSize, const unsigned short *src);
extern unsigned short *sqUTF8ToUTF16New(const char *string);
extern char *sqUTF16ToUTF8New(const unsigned short *wstring);

#endif /* SQ_TEXT_ENCODING_H */
