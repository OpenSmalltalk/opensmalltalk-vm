/* It's a mystery to me why they even bothered with /usr/include on SunOS
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

/* Author: Ian Piumarta
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
