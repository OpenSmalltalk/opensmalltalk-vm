/* PseudoTTYPlugin.c -- support for Unix98-style pseudo ttys		-*- C -*-
 * 
 * Author:	Ian Piumarta <ian.piumarta@inria.fr>
 * Version:	1.1
 * Last edited:	2003-09-03 18:06:13 by piumarta on emilia.inria.fr
 * 
 * This plugin extends AsynchFilePlugin with support for Unix98-style
 * pseudo ttys.  See the PseudoTTY and PseudoTTYPlugin class comments
 * for details.
 * 
 * Note that `Unix98' does NOT imply that this will only work on Unix
 * systems!  Unix98 is the name of a *standard* describing (amonst
 * many other things) one possible implementation of pseudo ttys that
 * could be adopted by any OS, be it Unix or something entirely
 * different.  (Unix98 ptys have been adopted by both BSD and Linux,
 * which is why we consider it the most interesting standard to
 * implement here.  However, be warned that if [for some bizarre,
 * masochistic reason] you have disabled Unix98 pty support in your
 * BSD or Linux kernel then this plugin will explode in your face.
 * [Although you should never get that far since the initial open of
 * /dev/ptmx will fail.])
 * 
 * Finally note that this plugin might (should) go away in the future
 * if (when) OSProcess implements the required support for pseudo ttys
 * and asynchronous i/o on their master devices.  (Dave: are you
 * reading this?)
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
 */

#include "sq.h"
#include "PseudoTTYPlugin.h"

/* Ian says: never EVER #include things in the Unix Squeak sources
   using relative paths.  Never.  Ever.  Period.  Write a Makefile.inc
   with the right XCPPFLAGS instead.  Having said that... */

#include "../AsynchFilePlugin/sqUnixAsynchFile.h"

#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>

#include "openpty.h"		/* hide the gory details ;) */

#if 0
# define DPRINTF(ARGS) printf ARGS
#else
# define DPRINTF(ARGS)
#endif


typedef struct Slave
{
  pid_t		 pid;		/* process */
  int		 status;	/* exit status */
  int		 pts;		/* pts (child pty) */
  FilePtr	 pty;		/* ptm (parent pty) */
  struct Slave	*next;		/* list */
} SlaveRec, *SlavePtr;

static SlavePtr slaves= 0;

typedef void (*sighandler_t)(int);

static sighandler_t prevchld= 0;
static int          reaping=  0;

#define isValid(f)	(f->sessionID == sqUnixAsyncFileSessionID)
#define validate(f)	if ((!isValid(f)) || (!(f->state))) return vm->primitiveFail()


/*** initialise-release ***/


#include "sqVirtualMachine.h"

static struct VirtualMachine *vm= 0;


static void sigchld(int signum)
{
  int	   status= 0;
  SlavePtr zombie= 0;
  pid_t	   pid=    wait(&status);

  if (!slaves)
    fprintf(stderr, "unexpected SIGCHLD for pid %d\n", pid);
  else
    for (zombie= slaves;  zombie;  zombie= zombie->next)
      if (zombie->pid == pid)
	break;
  if (!zombie)
    fprintf(stderr, "failed to clean up for pid %d\n", pid);
  else
    {
      /* force any image server loop to exit */
      /* close(zombie->pty->fd); */
      zombie->pty->rd.status= -2;
      signalSemaphoreWithIndex(zombie->pty->sema);
      DPRINTF(("closed pty for pid %d\n", pid));
    }
}


int ptyInit(void)
{
  DPRINTF(("ptyInit: AsyncFileSession is %d\n", sqUnixAsyncFileSessionID));
  vm= sqGetInterpreterProxy();
  slaves= 0;
  prevchld= signal(SIGCHLD, sigchld);
  if ((prevchld != SIG_DFL) && (prevchld != SIG_IGN))
    {
      fprintf(stderr, "declining responsibility for child processes!\n");
      signal(SIGCHLD, prevchld);
      reaping= 0;
    }
  else
    reaping= 1;
  return 1;
}


int ptyShutdown(void)
{
  if (reaping)
    {
      SlavePtr slave= 0;
      for (slave= slaves;  slave;  slave= slave->next)
	kill(slave->pid, SIGTERM);
      usleep(200*1000);
      for (slave= slaves;  slave;  slave= slave->next)
	kill(slave->pid, SIGKILL);
      usleep(200*1000);
      signal(SIGCHLD, prevchld);
      while (slaves)
	{
	  slave= slaves->next;
	  fprintf(stderr, "child process %d refused to die\n", slaves->pid);
	  free(slaves);
	  slaves= slave;
	}
    }
  slaves= 0;
  return 1;
}


/*** primitives ***/


#include <fcntl.h>
#include <time.h>


int ptyForkAndExec(AsyncFile *f, int semaIndex,
		   int cmdIndex, int cmdLen, int argIndex, int argLen)
{
  int ptm= -1, pts= -1;
  char tty[32];
  FilePtr fp= 0;

  DPRINTF(("ptyForkAndExec\n"));

  /* Module init must succeed in loading the AsyncFile plugin */
  if (sqUnixAsyncFileSessionID == 0)
    {
      vm->primitiveFail();
      return 0;
    }

  DPRINTF(("AsyncFileSession is %d\n", sqUnixAsyncFileSessionID));

  if (openpty(&ptm, &pts, tty, 0, 0) == -1)
    {
      perror("pty: openpty");
      goto failDetached;
    }
  DPRINTF(("pty: using %s (ptm %d pts %d)\n", tty, ptm, pts));

  if ((fp= asyncFileAttach(f, ptm, semaIndex)) == 0)
    goto failDetached;

  /* fork the child on the new pts (from now on we must detach on fail) */
  {
    extern char **environ;
    char    *cmd= (char *)alloca(cmdLen + 1);
    char   **argv= (char **)alloca(sizeof(char *) * (argLen + 2));
    int      i= 0;
    SlavePtr slave= 0;

    memcpy((void *)cmd, (void *)cmdIndex, cmdLen);
    cmd[cmdLen]= '\0';
    DPRINTF(("pty: command: %s\n", cmd));
    argv[0]= cmd;
    for (i= 1;  i <= argLen;  ++i)
      {
	int argOop= ((int *)argIndex)[i - 1];
	char *arg= 0;
	int   len= 0;
	if (!vm->isBytes(argOop)) goto fail;
	len= vm->stSizeOf(argOop);
	DPRINTF(("pty: arg %d len %d\n", i, len));
	arg= (char *)alloca(len + 1);
	memcpy((void *)arg, (void *)vm->firstIndexableField(argOop), len);
	arg[len]= '\0';
	argv[i]= arg;
	DPRINTF(("pty: argv[%d]: %s\n", i, argv[i]));
      }
    argv[argLen+1]= 0;	/* argv terminator */

    /* put slave on list in case of immediate exit in child */
    slave= (SlavePtr)malloc(sizeof(SlaveRec));
    slave->next= slaves;
    slaves= slave;
    slave->pts= pts;
    slave->pty= fp;
    slave->pid= fork();

    switch (slave->pid)
      {
      case -1:			/* error */
	slaves= slaves->next;
	free(slave);
	perror("pty: fork");
	goto fail;
	break;

      case 0:			/* child */
	close(ptm);
	login_tty(pts);
	execve(cmd, argv, environ);
	fprintf(stderr, "pty: ");
	perror(cmd);
	exit(1);
	break;

      default:			/* parent */
	close(pts);
	break;
      }
    return 0;
  }

 fail:
  asyncFileClose(f);
  ptm= -1;

 failDetached:
  if (ptm >= 0) close(ptm);
  if (pts >= 0) close(pts);
  vm->primitiveFail();
  return 0;
}


int ptyClose(AsyncFile *f)
{
  SlavePtr slave= 0, prev= 0;
  FilePtr  pty= (FilePtr)f->state;
  validate(f);
  DPRINTF(("pty: close %d\n", pty->fd));
  if (pty->fd >= 0)
    {
      for (prev= 0, slave= slaves;  slave;  prev= slave, slave= slave->next)
	if (slave->pty == pty)
	  {
	    int pid= slave->pid;
	    DPRINTF(("killing pid %d connected to pts %d\n", pid, slave->pts));
	    /* terminate with increasing degrees of violence... */
	    kill(pid, SIGTERM);
	    usleep(200*1000);
	    kill(pid, SIGKILL);
	    /* delete from list */
	    if (prev)
	      prev->next= slave->next;
	    else
	      slaves= slave->next;
	    break;
	  }
      if (slave)
	free(slave);
      else
	fprintf(stderr, "pty %d not in active process list\n", pty->fd);
    }
  asyncFileClose(f);
  return 0;
}


ptyWindowSize(AsyncFile *f, int cols, int rows)
{
#if defined(TIOCSWINSZ)
  struct winsize sz;
  FilePtr pty= (FilePtr)f->state;
  validate(f);
  DPRINTF(("pty %d size %d %d\n", pty->fd, cols, rows));
  sz.ws_col= cols;
  sz.ws_row= rows;
  sz.ws_xpixel= sz.ws_ypixel= 0;
  if (ioctl(pty->fd, TIOCSWINSZ, &sz) == -1)
    perror("pty: TIOCSWINSZ");
#endif
  return 0;
}
