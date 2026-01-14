# Makefile.plg.in -- default rules for plugins		-*- makefile -*-
# 
#   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
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
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
# 
# Author: ian.piumarta@inria.fr
# 
# Last edited: 2006-10-18 10:13:37 by piumarta on emilia.local


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

XINCLUDES	=  -I/home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin 
OBJS		=  FloatMathPlugin$o acos$o acosh$o asin$o asinh$o atan$o atan2$o atanh$o copysign$o cos$o cosh$o exp$o expm1$o finite$o fmod$o hypot$o isnan$o k_cos$o k_rem_pio2$o k_sin$o k_tan$o ldexp$o log$o log10$o log1p$o modf$o pow$o rem_pio2$o rint$o scalb$o scalbn$o sin$o sinh$o sqrt$o tan$o tanh$o
TARGET		= FloatMathPlugin$a
PLIBS		= 


XCFLAGS = $(LIBM_CFLAGS) -DNO_ISNAN=1

$(TARGET) : $(OBJS) Makefile
	$(LINK) $(TARGET) $(OBJS) $(PLIBS)
	$(RANLIB) $(TARGET)




FloatMathPlugin$o : /home/kend/Kens-VM/src/plugins/FloatMathPlugin/FloatMathPlugin.c
	$(COMPILE) FloatMathPlugin$o /home/kend/Kens-VM/src/plugins/FloatMathPlugin/FloatMathPlugin.c

acos$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/acos.c
	$(COMPILE) acos$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/acos.c

acosh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/acosh.c
	$(COMPILE) acosh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/acosh.c

asin$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/asin.c
	$(COMPILE) asin$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/asin.c

asinh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/asinh.c
	$(COMPILE) asinh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/asinh.c

atan$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atan.c
	$(COMPILE) atan$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atan.c

atan2$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atan2.c
	$(COMPILE) atan2$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atan2.c

atanh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atanh.c
	$(COMPILE) atanh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/atanh.c

copysign$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/copysign.c
	$(COMPILE) copysign$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/copysign.c

cos$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/cos.c
	$(COMPILE) cos$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/cos.c

cosh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/cosh.c
	$(COMPILE) cosh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/cosh.c

exp$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/exp.c
	$(COMPILE) exp$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/exp.c

expm1$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/expm1.c
	$(COMPILE) expm1$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/expm1.c

finite$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/finite.c
	$(COMPILE) finite$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/finite.c

fmod$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/fmod.c
	$(COMPILE) fmod$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/fmod.c

hypot$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/hypot.c
	$(COMPILE) hypot$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/hypot.c

isnan$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/isnan.c
	$(COMPILE) isnan$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/isnan.c

k_cos$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_cos.c
	$(COMPILE) k_cos$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_cos.c

k_rem_pio2$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_rem_pio2.c
	$(COMPILE) k_rem_pio2$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_rem_pio2.c

k_sin$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_sin.c
	$(COMPILE) k_sin$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_sin.c

k_tan$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_tan.c
	$(COMPILE) k_tan$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/k_tan.c

ldexp$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/ldexp.c
	$(COMPILE) ldexp$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/ldexp.c

log$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log.c
	$(COMPILE) log$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log.c

log10$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log10.c
	$(COMPILE) log10$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log10.c

log1p$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log1p.c
	$(COMPILE) log1p$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/log1p.c

modf$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/modf.c
	$(COMPILE) modf$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/modf.c

pow$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/pow.c
	$(COMPILE) pow$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/pow.c

rem_pio2$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/rem_pio2.c
	$(COMPILE) rem_pio2$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/rem_pio2.c

rint$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/rint.c
	$(COMPILE) rint$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/rint.c

scalb$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/scalb.c
	$(COMPILE) scalb$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/scalb.c

scalbn$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/scalbn.c
	$(COMPILE) scalbn$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/scalbn.c

sin$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sin.c
	$(COMPILE) sin$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sin.c

sinh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sinh.c
	$(COMPILE) sinh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sinh.c

sqrt$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sqrt.c
	$(COMPILE) sqrt$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/sqrt.c

tan$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/tan.c
	$(COMPILE) tan$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/tan.c

tanh$o : /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/tanh.c
	$(COMPILE) tanh$o /home/kend/Kens-VM/platforms/Cross/plugins/FloatMathPlugin/tanh.c

.force :
