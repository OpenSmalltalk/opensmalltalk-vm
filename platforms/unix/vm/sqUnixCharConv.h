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
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 * Last edited: 2005-03-17 21:11:25 by piumarta on squeak.hpl.hp.com
 */

#ifndef __sqUnixCharConv_h
#define __sqUnixCharConv_h

extern void *sqTextEncoding;
extern void *uxTextEncoding;
extern void *uxPathEncoding;
extern void *uxUTF8Encoding;
extern void *uxXWinEncoding;

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

#endif /* __sqUnixCharConv_h */
