/* It's a mystery to me why they even bothered with /usr/include on SunOS
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
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
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Last edited: Wed Aug 16 06:21:25 2000 by piumarta (Ian Piumarta) on emilia
 */

#ifndef __squeak__sunos_h
#define __squeak__sunos_h

/* stdio.h */

extern int printf();

#define SEEK_SET	0
#define SEEK_CUR	1
#define SEEK_END	2

extern int fread();
extern int fclose();
extern int fseek();
extern int fprintf();

extern int sscanf();

extern int perror();

/* stdlib.h */

extern int strtol();

/* unistd.h */

extern int gethostname();
extern int gettimeofday();
extern int lstat();
extern int realpath();

/* string.h */

extern int bzero();
#include <memory.h>

/* netdb.h */

extern int h_errno;

/* dlfcn.h */

#define RTLD_NOW	1

/* time.h */

#include <sys/param.h>

#define CLK_TCK		HZ

extern int clock();
extern int time();

/* sys/types.h */

typedef int ssize_t;

/* sys/time.h */

extern int setitimer();

/* sys/socket.h */

extern int accept();
extern int bind();
extern int connect();
extern int getsockname();
extern int getpeername();
extern int listen();
extern int recvfrom();
extern int select();
extern int sendto();
extern int setsockopt();
extern int socket();

/* sys/ioctl.h */

extern int ioctl();

#endif /* !__squeak__sunos_h */
