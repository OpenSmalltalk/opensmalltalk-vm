/* openpty.h -- provides openpty() and login_tty()
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
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
 * Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2003-09-03 17:42:22 by piumarta on emilia.inria.fr
 */

#if defined(HAVE_OPENPTY)

# include <utmp.h>		/* login_tty() */
# if defined(HAVE_PTY_H)
#   include <pty.h>		/* openpty() */
# elif defined(HAVE_UTIL_H)
#   include <util.h>		/* openpty() */
# elif defined(HAVE_LIBUTIL_H)
#   include <libutil.h>		/* openpty() on FreeBSD */
# else
#   error: cannot find headers for openpty()
# endif

#else /* !HAVE_OPENPTY */

# if defined(HAVE_UNIX98_PTYS)

    /* we'll just roll our own, it ain't hard */

#   include <stdlib.h>	/* ptsname(), grantpt(), unlockpt() */
#   include <unistd.h>
#   include <string.h>
#   include <fcntl.h>
#   if defined(HAVE_STROPTS_H)
#     include <stropts.h>
#     include <sys/ioctl.h>
#   endif

static int openpty(int *ptmp, int *ptsp, char *ttyp, void *termiosp, void *winp)
{
  int   ptm= -1, pts= -1;
  char *tty= 0;
  if ((ptm= open("/dev/ptmx", O_RDWR, 0)) == -1) return -1;
  tty= ptsname(ptm);
  if (grantpt(ptm)  == -1) return -1;
  if (unlockpt(ptm) == -1) return -1;
  if ((pts= open(tty, O_RDWR, 0)) == -1) return -1;
  *ptmp= ptm;
  *ptsp= pts;
  strcpy(ttyp, tty);
  return 0;
}

static int login_tty(int pts)
{
#if defined(HAVE_STROPTS_H)
  /* push a terminal onto stream head */
  if (ioctl(pts, I_PUSH, "ptem")   == -1) return -1;
  if (ioctl(pts, I_PUSH, "ldterm") == -1) return -1;
#endif
  setsid();
#if defined(TIOCSCTTY)
  ioctl(pts, TIOCSCTTY, 0);
#endif
  dup2(pts, 0);
  dup2(pts, 1);
  dup2(pts, 2);
  if (pts > 2) close(pts);
  return 0;
}

# else /* !HAVE_UNIX98_PTYS */
#   error: cannot open a pty -- this plugin will not work
# endif
#endif /* !HAVE_OPENPTY */
