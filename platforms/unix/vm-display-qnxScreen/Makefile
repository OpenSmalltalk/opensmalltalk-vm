# Makefile for framebuffer support				-*- makefile -*-
# 
#   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
#                              listed elsewhere in this file.
#   All rights reserved.
#   
#   This file is part of Unix Squeak.
# 
#      You are NOT ALLOWED to distribute modified versions of this file
#      under its original name.  If you modify this file then you MUST
#      rename it before making your modifications available publicly.
# 
#   This file is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE.
#   
#   You may use and/or distribute this file ONLY as part of Squeak, under
#   the terms of the Squeak License as described in `LICENSE' in the base of
#   this distribution, subject to the following additional restrictions:
# 
#   1. The origin of this software must not be misrepresented; you must not
#      claim that you wrote the original software.  If you use this software
#      in a product, an acknowledgment to the original author(s) (and any
#      other contributors mentioned herein) in the product documentation
#      would be appreciated but is not required.
# 
#   2. You must not distribute (or make publicly available by any
#      means) a modified copy of this file unless you first rename it.
# 
#   3. This notice must not be removed or altered in any source distribution.
# 
#   Using (or modifying this file for use) in any context other than Squeak
#   changes these copyright conditions.  Read the file `COPYING' in the
#   directory `platforms/unix/doc' before proceeding with any such use.
# 
# Author: ian.piumarta@inria.fr
# 
# Last edited: 2004-04-12 11:56:39 by piumarta on emilia.local


# make.cfg.in -- mf fragment for configured variables		-*- makefile -*-
# 
#   Copyright (C) 1996-2015 by Ian Piumarta and other authors/contributors
#                              listed elsewhere in this file.
#   All rights reserved.
#   
#   This file is part of Unix Squeak.
# 
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
# 
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
# 
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#	DEALINGS IN THE SOFTWARE.

# Author: Ian.Piumarta@inria.fr
# 
# Last edited: Wed Nov 16 14:47:35 PST 2016 by eliot

MAKEFLAGS=	--no-print-directory



host=		aarch64-rpi4-qnx-gnu
host_cpu=	aarcg64
target_cpu=	aarch64
host_vendor=	rpi4
host_os=	qnx-gnu

topdir=		/home/kend/Kens-VM
cfgdir=		/home/kend/Kens-VM/platforms/unix/config
srcdir=		/home/kend/Kens-VM/src/spur64.stack
vmmcfg=		/home/kend/Kens-VM/building/qnx64ARMv8/squeak.stack.spur/build
blddir=		/home/kend/Kens-VM/building/qnx64ARMv8/squeak.stack.spur/build

scriptname=	spur64

top_builddir=	/home/kend/Kens-VM/building/qnx64ARMv8/squeak.stack.spur/build

prefix=		/usr/local
exec_prefix=	${prefix}

bindir=		${exec_prefix}/bin
libdir=		${exec_prefix}/lib
datarootdir=	${prefix}/share
datadir=	${datarootdir}
mandir=		${datarootdir}/man
imgdir=		${prefix}/lib/squeak
plgdir=		.
docdir=		$(prefix)/doc/squeak

SHELL=		/bin/bash
MKINSTALLDIRS=	mkdir -p
INSTALL=	/usr/bin/install -c
INSTALL_PROG=	${INSTALL} $(INSTALL_ARGS)
INSTALL_SCRIPT=	${INSTALL} $(INSTALL_ARGS)
INSTALL_DATA=	${INSTALL} -m 644 $(INSTALL_ARGS)
UNINSTALL=	$(SHELL) $(cfgdir)/uninstall
AS=		as
AWK=		mawk
RANLIB=		ranlib
LIBTOOL=	$(SHELL) $(top_builddir)/libtool
NM=		/usr/bin/nm -B
LN=		ln
LN_S=		ln -s

CC=		$(QNX_CC)
DEFS=		-DHAVE_CONFIG_H
INCLUDES=	-I/home/kend/Kens-VM/building/qnx64ARMv8/squeak.stack.spur/build -I/home/kend/Kens-VM/building/qnx64ARMv8/squeak.stack.spur/build -I/home/kend/Kens-VM/platforms/unix/vm -I/home/kend/Kens-VM/platforms/Cross/vm -I/home/kend/Kens-VM/src/spur64.stack -I/usr/local/include
CPPFLAGS=	 -Wno-missing-braces -Wno-unknown-pragmas -Wno-unused-value -Wno-unused-label -Wno-unused-function -Wno-unused-variable -Wno-unused-but-set-variable $(QNX_CFLAGS)
CFLAGS=		-Wall  -fPIC  -g -O2 -DNDEBUG -DDEBUGVM=0 -DCOGMTVM=0 -DLSB_FIRST=1 $(QNX_CFLAGS)
WFLAGS=		
LDFLAGS=	 -Wl,-z,now -lscreen $(QNX_LIBS) $(QNX_LDFLAGS)
BITBLT_OBJS=	BitBltPlugin.o
IA32ABI_OBJS=	IA32ABI.o AlienSUnitTestProcedures.o xabicc.o
VM_DISPX11_OBJS= 
BITBLT_FLAGS=   
VM_DISPX11_BITBLT_FLAGS= 
ARM_ARCH= 
LIBM_CFLAGS=	-O

FT2_PLUGIN_CFLAGS = 
FT2_PLUGIN_LIBS = 
UNICODE_PLUGIN_CFLAGS = 
UNICODE_PLUGIN_LIBS = 

LIBS=		-lz -lm $(QNX_LIBS) $(QNX_LDFLAGS) 


X_CFLAGS=	
X_INCLUDES=	
X_LIBS=		


INTERP=		gcc3x-interp

VM_APP_ICONS=	

npsqueak=	
install_nps=	
uninstall_nps=	

# make.ext.in -- mf fragment for external plugins		-*- makefile -*-
# 
# Author: Ian.Piumarta@inria.fr
# 
# Last edited: Sep  1 18:56:15 PDT 2010 by eliot; LINKXX for plugins using C++

o		= .lo
a		= .la
COMPILE		= $(CC) $(CFLAGS) $(CPPFLAGS) $(XCFLAGS) $(DEFS) $(XDEFS) \
		  $(INCLUDES) $(XINCLUDES) $(CPPFLAGS) $(XCPPFLAGS) $(TARGET_ARCH) -c -o
CXXFLAGS	= $(CFLAGS) # Hack; can't be bothered to add CXXFLAGS to the configure mess
COMPILE.cpp	 = $(COMPILE.cc)
COMPILE.cc	= $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(XCFLAGS) $(DEFS) $(XDEFS) \
		  $(INCLUDES) $(XINCLUDES) $(CPPFLAGS) $(XCPPFLAGS) $(TARGET_ARCH) -shared -c -o
LINK		= $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -shared -o
LINKXX		= $(CXX) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH)  -shared -o
RANLIB		= :

TARGET		= vm-display-qnxScreen.so
OBJS		= sqQNXScreen$o

#XCFLAGS		= $(X_CFLAGS) -Wall -Werror -Wno-unknown-pragmas
XCFLAGS		= $(X_CFLAGS) -Wall -Wno-unknown-pragmas

XINCLUDES	=  -I/home/kend/Kens-VM/platforms/unix/vm-display-qnxScreen  $(X_INCLUDES) $(QNX_CFLAGS) \
		  -I$(topdir)/platforms/Cross/plugins/FilePlugin \
		  -I$(topdir)/platforms/Cross/plugins/B3DAcceleratorPlugin \
		  -I$(topdir)/platforms/unix/plugins/B3DAcceleratorPlugin

$(TARGET) : $(OBJS) Makefile
	$(LINK) $(TARGET) $(OBJS)

sqQNXScreen$o : /home/kend/Kens-VM/platforms/unix/vm-display-qnxScreen/sqQNXScreen.c
	$(COMPILE) sqQNXScreen$o /home/kend/Kens-VM/platforms/unix/vm-display-qnxScreen/sqQNXScreen.c

.force :
