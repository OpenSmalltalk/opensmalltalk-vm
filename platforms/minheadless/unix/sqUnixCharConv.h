/* sqUnixCharConv.h -- conversion between character encodings
 * 
 * Author: Ian.Piumarta@squeakland.org
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 * 
 * Last edited: 2008-03-19 14:43:16 by piumarta on emilia.local
 */

#ifndef __sqUnixCharConv_h
#define __sqUnixCharConv_h

extern void *sqTextEncoding;
extern void *uxTextEncoding;
extern void *uxPathEncoding;
extern void *uxUTF8Encoding;
extern void *uxXWinEncoding;
extern void *localeEncoding;

extern void setEncoding(void **encoding, char *name);

extern int convertChars(char *from, int fromLen, void *fromCode,
			char *to,   int toLen,   void *toCode,
			int norm, int term);

extern int sq2uxText(char *from, int fromLen, char *to, int toLen, int term);
extern int ux2sqText(char *from, int fromLen, char *to, int toLen, int term);
extern int sq2uxPath(char *from, int fromLen, char *to, int toLen, int term);
extern int ux2sqPath(char *from, int fromLen, char *to, int toLen, int term);
extern int sq2uxUTF8(char *from, int fromLen, char *to, int toLen, int term);
extern int ux2sqUTF8(char *from, int fromLen, char *to, int toLen, int term);
extern int ux2sqXWin(char *from, int fromLen, char *to, int toLen, int term);

extern void freeEncoding(void *encoding);
extern void setNEncoding(void **encoding, char *rawName, int n);
extern void setLocaleEncoding(char *locale);

#endif /* __sqUnixCharConv_h */
