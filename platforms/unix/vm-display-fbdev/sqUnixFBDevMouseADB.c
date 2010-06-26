/* sqUnixFBDevMouseADB.c -- simplicity unique to the Apple Desktop Bus mouse
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2003-08-20 01:14:47 by piumarta on felina.inria.fr
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
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
 */


static void ms_adb_init(_self) { DPRINTF("ADB init\n"); }


static void ms_adb_handleEvents(_self)
{
  unsigned char cmd[3];

  while (3 == ms_read(self, cmd, 3, 3, 0))
    if (0x80 == (cmd[0] & 0xf8))
      self->callback((cmd[0] & 7) ^ 7, (signed char)cmd[1], -(signed char)cmd[2]);
}
