/* sqUnixSound.c -- sound support for various Unix sound systems
 *
 * Authors: Ian.Piumarta@inria.fr and Lex Spoon <lex@cc.gatech.edu>
 * 
 * Last edited: 2002-10-26 14:37:22 by piumarta on emilia.inria.fr
 *
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 *   You are not allowed to distribute a modified version of this file
 *   under its original name without explicit permission to do so.  If
 *   you change it, rename it.
 *
 * NOTE: The real sound support code is in one of the following files according
 *	 to the output driver selected by `configure':
 * 
 *	   sqUnixSoundOSS.c	(Open Sound System [incl. Linux native & ALSA compat])
 *	   sqUnixSoundNAS.c	(Network Audio System)
 *	   sqUnixSoundSun.c	(SunOS/Solaris)
 *	   sqUnixSoundNone.c	(no sound support)
 */

#include "sq.h"
#include "SoundPlugin.h"

extern int snd_Stop(void);


/*** module initialisation/shutdown ***/


int soundInit(void)
{
  return 1;
}


int soundShutdown(void)
{
  snd_Stop();
  return 1;
}
