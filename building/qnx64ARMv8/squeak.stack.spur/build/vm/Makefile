# Makefile for core VM				-*- makefile -*-
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
# Last edited: 2003-08-22 22:54:19 by piumarta on emilia.inria.fr


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
plgdir=		${imgdir}/`${blddir}/getversion VERSION_TAG`
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
CFLAGS=		-Wall   -g -O2 -DNDEBUG -DDEBUGVM=0 -DCOGMTVM=0 -DLSB_FIRST=1 $(QNX_CFLAGS)
WFLAGS=		
LDFLAGS=	 -Wl,-z,now $(QNX_LIBS) $(QNX_LDFLAGS)
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

# make.int.in -- mf fragment for internal plugins		-*- makefile -*-
# 
# Author: Ian.Piumarta@inria.fr
# 
# Last edited: 2002-07-08 20:31:51 by piumarta on emilia.inria.fr

o		= .o
a		= .a
COMPILE		= $(CC) $(CFLAGS) $(CPPFLAGS) $(XCFLAGS) $(DEFS) $(XDEFS) -DSQUEAK_BUILTIN_PLUGIN \
		  $(INCLUDES) $(XINCLUDES) $(CPPFLAGS) $(XCPPFLAGS) $(TARGET_ARCH) -c -o
LINK		= $(AR) -rc
RANLIB		= ranlib

TARGET		= vm$a
COBJS		= $(INTERP)$o cogit$o sqNamedPrims$o sqVirtualMachine$o sqHeapMap$o\
			sqExternalSemaphores$o sqTicker$o aio$o debug$o osExports$o \
			sqUnixExternalPrims$o sqUnixMemory$o sqUnixSpurMemory$o \
			sqUnixCharConv$o sqUnixMain$o \
			sqUnixVMProfile$o sqUnixHeartbeat$o sqUnixThreads$o \
			sqUnixDisplayHelpers$o

IOBJS		= $(INTERP)$o sqNamedPrims$o sqVirtualMachine$o sqHeapMap$o\
			sqExternalSemaphores$o sqTicker$o aio$o debug$o osExports$o \
			sqUnixExternalPrims$o sqUnixMemory$o sqUnixSpurMemory$o \
			sqUnixCharConv$o sqUnixMain$o \
			sqUnixVMProfile$o sqUnixHeartbeat$o sqUnixThreads$o \
			sqUnixDisplayHelpers$o

OBJS		= $(IOBJS) # see mkmf

XINCLUDES	=  -I/home/kend/Kens-VM/platforms/Cross/vm -I/home/kend/Kens-VM/platforms/unix/vm -I/home/kend/Kens-VM/src/spur64.stack  \
		  -I$(topdir)/platforms/Cross/plugins/FilePlugin \
		  -I$(topdir)/platforms/unix/plugins/B3DAcceleratorPlugin

$(TARGET) : $(OBJS) Makefile
	$(LINK) $(TARGET) $(OBJS)
	$(RANLIB) $(TARGET)

$(blddir)/sqNamedPrims.h:	$(vmmcfg)/plugins.int
	$(topdir)/mkNamedPrims.sh $(vmmcfg)/plugins.int >$(blddir)/sqNamedPrims.h

# rebuild sqNamedPrims.o if sqNamedPrims.h changes

sqNamedPrims$o : $(blddir)/sqNamedPrims.h

# cogit.c merely includes specific a specific cogitPROCESSOR.c
# e.g. cogitARMv5.c cogitIA32.c cogitX64SysV.c cogitARMv8.c et al
cogit$o : $(srcdir)/cogit.c $(srcdir)/cogit.h $(srcdir)/cointerp.h $(wildcard $(srcdir)/cogit.*.c)

$(INTERP)$o : $(wildcard $(srcdir)/cogit.h)

# sqUnixHeartbeat.c includes sqSCCSVersion.h
sqUnixHeartbeat$o : $(topdir)/platforms/Cross/vm/sqSCCSVersion.h

# rebuild sqExtPrims sqUnixMain if config.h changes

sqUnixExternalPrims$o sqUnixMain$o : ../config.h $(topdir)/platforms/unix/vm/dlfcn-dyld.c

sqUnixDisplayHelpers$o: ../config.h

sqUnixMemory$o : $(topdir)/platforms/unix/vm/sqUnixSpurMemory.c




gcc3x-interp$o : /home/kend/Kens-VM/src/spur64.stack/gcc3x-interp.c
	$(COMPILE) gcc3x-interp$o /home/kend/Kens-VM/src/spur64.stack/gcc3x-interp.c

interp$o : /home/kend/Kens-VM/src/spur64.stack/interp.c
	$(COMPILE) interp$o /home/kend/Kens-VM/src/spur64.stack/interp.c

validImage$o : /home/kend/Kens-VM/src/spur64.stack/validImage.c
	$(COMPILE) validImage$o /home/kend/Kens-VM/src/spur64.stack/validImage.c

sqExternalSemaphores$o : /home/kend/Kens-VM/platforms/Cross/vm/sqExternalSemaphores.c
	$(COMPILE) sqExternalSemaphores$o /home/kend/Kens-VM/platforms/Cross/vm/sqExternalSemaphores.c

sqHeapMap$o : /home/kend/Kens-VM/platforms/Cross/vm/sqHeapMap.c
	$(COMPILE) sqHeapMap$o /home/kend/Kens-VM/platforms/Cross/vm/sqHeapMap.c

sqNamedPrims$o : /home/kend/Kens-VM/platforms/Cross/vm/sqNamedPrims.c
	$(COMPILE) sqNamedPrims$o /home/kend/Kens-VM/platforms/Cross/vm/sqNamedPrims.c

sqPath$o : /home/kend/Kens-VM/platforms/Cross/vm/sqPath.c
	$(COMPILE) sqPath$o /home/kend/Kens-VM/platforms/Cross/vm/sqPath.c

sqTextEncoding$o : /home/kend/Kens-VM/platforms/Cross/vm/sqTextEncoding.c
	$(COMPILE) sqTextEncoding$o /home/kend/Kens-VM/platforms/Cross/vm/sqTextEncoding.c

sqTicker$o : /home/kend/Kens-VM/platforms/Cross/vm/sqTicker.c
	$(COMPILE) sqTicker$o /home/kend/Kens-VM/platforms/Cross/vm/sqTicker.c

sqVirtualMachine$o : /home/kend/Kens-VM/platforms/Cross/vm/sqVirtualMachine.c
	$(COMPILE) sqVirtualMachine$o /home/kend/Kens-VM/platforms/Cross/vm/sqVirtualMachine.c

aio$o : /home/kend/Kens-VM/platforms/unix/vm/aio.c
	$(COMPILE) aio$o /home/kend/Kens-VM/platforms/unix/vm/aio.c

debug$o : /home/kend/Kens-VM/platforms/unix/vm/debug.c
	$(COMPILE) debug$o /home/kend/Kens-VM/platforms/unix/vm/debug.c

dlfcn-dyld$o : /home/kend/Kens-VM/platforms/unix/vm/dlfcn-dyld.c
	$(COMPILE) dlfcn-dyld$o /home/kend/Kens-VM/platforms/unix/vm/dlfcn-dyld.c

mac-alias$o : /home/kend/Kens-VM/platforms/unix/vm/mac-alias.c
	$(COMPILE) mac-alias$o /home/kend/Kens-VM/platforms/unix/vm/mac-alias.c

osExports$o : /home/kend/Kens-VM/platforms/unix/vm/osExports.c
	$(COMPILE) osExports$o /home/kend/Kens-VM/platforms/unix/vm/osExports.c

sqQNXScreenDisplay$o : /home/kend/Kens-VM/platforms/unix/vm/sqQNXScreenDisplay.c
	$(COMPILE) sqQNXScreenDisplay$o /home/kend/Kens-VM/platforms/unix/vm/sqQNXScreenDisplay.c

sqUnixCharConv$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixCharConv.c
	$(COMPILE) sqUnixCharConv$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixCharConv.c

sqUnixDisplayHelpers$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixDisplayHelpers.c
	$(COMPILE) sqUnixDisplayHelpers$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixDisplayHelpers.c

sqUnixEvent$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixEvent.c
	$(COMPILE) sqUnixEvent$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixEvent.c

sqUnixExternalPrims$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixExternalPrims.c
	$(COMPILE) sqUnixExternalPrims$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixExternalPrims.c

sqUnixHeartbeat$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixHeartbeat.c
	$(COMPILE) sqUnixHeartbeat$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixHeartbeat.c

sqUnixITimerHeartbeat$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixITimerHeartbeat.c
	$(COMPILE) sqUnixITimerHeartbeat$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixITimerHeartbeat.c

sqUnixITimerTickerHeartbeat$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixITimerTickerHeartbeat.c
	$(COMPILE) sqUnixITimerTickerHeartbeat$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixITimerTickerHeartbeat.c

sqUnixMain$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixMain.c
	$(COMPILE) sqUnixMain$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixMain.c

sqUnixMemory$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixMemory.c
	$(COMPILE) sqUnixMemory$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixMemory.c

sqUnixSpurMemory$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixSpurMemory.c
	$(COMPILE) sqUnixSpurMemory$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixSpurMemory.c

sqUnixThreads$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixThreads.c
	$(COMPILE) sqUnixThreads$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixThreads.c

sqUnixVMProfile$o : /home/kend/Kens-VM/platforms/unix/vm/sqUnixVMProfile.c
	$(COMPILE) sqUnixVMProfile$o /home/kend/Kens-VM/platforms/unix/vm/sqUnixVMProfile.c

# Ensure the heartbeat is compiled with less aggressive optimization.  At
# least with gcc 4.1.2 compiling with -O2 results in an apparently flakey VM;
# so flakey the Squeak4.2-10856-beta.image image won't even start-up.
#sqUnixHeartbeat$o : $(topdir)/platforms/unix/vm/sqUnixHeartbeat.c
#	$(COMPILE) sqUnixHeartbeat$o -O1 -fno-omit-frame-pointer -mno-rtd -mno-accumulate-outgoing-args $(topdir)/platforms/unix/vm/sqUnixHeartbeat.c

# Ensure the cointerpreter is compiled with less aggressive optimization.  At
# least with gcc 4.1.2 compiling with -O2 results in an apparently flakey VM.
#gcc3x-cointerp$o : $(srcdir)/vm/gcc3x-cointerp.c
#	$(COMPILE) gcc3x-cointerp$o -O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args $(srcdir)/vm/gcc3x-cointerp.c

# Ensure the cogit is compiled with less aggressive optimization.  The cogit
# contains a function that does two alloca's which is miscompiled by a number of
# optimizing compilers (at least gcc 4.0.x 4.1.x & Intel icc 10.1) under the
# -fomit-frame-pointer regime.  Also on gcc 4.1 linux -O2 causes an abort on
# shutdown even though the VM starts correctly.  You have been warned :)
#cogit$o : $(srcdir)/vm/cogit.c
#	$(COMPILE) cogit$o -O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer -mno-rtd -mno-accumulate-outgoing-args $(srcdir)/vm/cogit.c

.force :
