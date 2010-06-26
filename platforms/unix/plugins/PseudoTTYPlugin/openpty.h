/* openpty.h -- provides openpty() and login_tty()
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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
 * Author: Ian.Piumarta@inria.fr
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
