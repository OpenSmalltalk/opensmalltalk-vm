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
 *    You are NOT ALLOWED to distribute modified versions of this file
 *    under its original name.  If you want to modify it and then make
 *    your modifications available publicly, rename the file first.
 * 
 * This file is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * You may use and/or distribute this file under the terms of the Squeak
 * License as described in `LICENSE' in the base of this distribution,
 * subject to the following additional restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software.  If you use this software
 *    in a product, an acknowledgment to the original author(s) (and any
 *    other contributors mentioned herein) in the product documentation
 *    would be appreciated but is not required.
 * 
 * 2. You must not distribute (or make publicly available by any
 *    means) a modified copy of this file unless you first rename it.
 * 
 * 3. This notice must not be removed or altered in any source distribution.
 */


static void ms_adb_init(_self) { dprintf("ADB init\n"); }


static void ms_adb_handleEvents(_self)
{
  unsigned char cmd[3];

  while (3 == ms_read(self, cmd, 3, 3, 0))
    if (0x80 == (cmd[0] & 0xf8))
      self->callback((cmd[0] & 7) ^ 7, (signed char)cmd[1], -(signed char)cmd[2]);
}
