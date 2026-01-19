# Makefile.in for Unix Squeak using VMMaker		-*- makefile -*-
# 
#   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
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
# Last edited: Sat May 23 18:45:43 PDT 2015 by eliot

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

topdir=		/home/kend/QNX-VM
cfgdir=		/home/kend/QNX-VM/platforms/unix/config
srcdir=		/home/kend/QNX-VM/src/spur64.stack
vmmcfg=		/home/kend/QNX-VM/building/qnx64ARMv8/squeak.stack.spur/build
blddir=		/home/kend/QNX-VM/building/qnx64ARMv8/squeak.stack.spur/build

scriptname=	spur64

top_builddir=	/home/kend/QNX-VM/building/qnx64ARMv8/squeak.stack.spur/build

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
INCLUDES=	-I/home/kend/QNX-VM/building/qnx64ARMv8/squeak.stack.spur/build -I/home/kend/QNX-VM/building/qnx64ARMv8/squeak.stack.spur/build -I/home/kend/QNX-VM/platforms/unix/vm -I/home/kend/QNX-VM/platforms/Cross/vm -I/home/kend/QNX-VM/src/spur64.stack -I/usr/local/include
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
# make.prg.in -- mf fragment for programs		-*- makefile -*-
# 
# Author: Ian.Piumarta@inria.fr, eliot, topa
# 

o		= .o
a		= .a
x		=
COMPILE		= $(CC) $(CFLAGS) $(CPPFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -c -o
COMPILEIFP	= $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -fno-omit-frame-pointer -c -o
CXXFLAGS	= $(CFLAGS) # Hack; can't be bothered to add CXXFLAGS to the configure mess
COMPILE.cpp = $(COMPILE.cc)
COMPILE.cc	= $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -c -o
LINK		= $(LIBTOOL) --mode=link \
		  $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -export-dynamic -o
RANLIB		= :

la		= .la

SQLIBS		=  vm/vm$a ADPCMCodecPlugin/ADPCMCodecPlugin$a B2DPlugin/B2DPlugin$a BitBltPlugin/BitBltPlugin$a BMPReadWriterPlugin/BMPReadWriterPlugin$a CroquetPlugin/CroquetPlugin$a HostWindowPlugin/HostWindowPlugin$a ZipPlugin/ZipPlugin$a DropPlugin/DropPlugin$a DSAPrims/DSAPrims$a FFTPlugin/FFTPlugin$a FileCopyPlugin/FileCopyPlugin$a FilePlugin/FilePlugin$a FileDialogPlugin/FileDialogPlugin$a Float64ArrayPlugin/Float64ArrayPlugin$a FloatArrayPlugin/FloatArrayPlugin$a FloatMathPlugin/FloatMathPlugin$a IA32ABI/IA32ABI$a JPEGReaderPlugin/JPEGReaderPlugin$a JPEGReadWriter2Plugin/JPEGReadWriter2Plugin$a Klatt/Klatt$a LargeIntegers/LargeIntegers$a Matrix2x3Plugin/Matrix2x3Plugin$a MiscPrimitivePlugin/MiscPrimitivePlugin$a RePlugin/RePlugin$a SecurityPlugin/SecurityPlugin$a SerialPlugin/SerialPlugin$a SocketPlugin/SocketPlugin$a SoundCodecPrims/SoundCodecPrims$a SoundGenerationPlugin/SoundGenerationPlugin$a SoundPlugin/SoundPlugin$a StarSqueakPlugin/StarSqueakPlugin$a SurfacePlugin/SurfacePlugin$a
PLUGINS_LA	=  vm-display-null${la} vm-display-qnxScreen${la} vm-sound-null${la} FileAttributesPlugin${la} SqueakFFIPrims${la} LocalePlugin${la} VectorEnginePlugin${la}

squeak		= squeak
squeaksh	= squeak.sh
binsqueaksh	= bin.squeak.sh

all : $(squeak) plugins squeak.1 $(npsqueak)

# VM

$(squeak) : config.sh $(SQLIBS) version.o
	$(LINK) $(squeak) $(SQLIBS) version.o $(LIBS) -lsocket -linputevents -liconv -lffi -lscreen -Wl,--whole-archive,vm/vm.a,--no-whole-archive
	@echo
	@size $(squeak)
	@echo
	@./$(squeak) -version || ./$(squeak) --version 
	@echo

version.o : version.c
	./compile-version.sh

version.c : $(SQLIBS)
	${cfgdir}/verstamp version.c $(CC)


getversion : ${cfgdir}/getversion.c ${topdir}/platforms/Cross/vm/sqSCCSVersion.h
	$(LINK) getversion $(INCLUDES) ${cfgdir}/getversion.c

plugins : config.sh $(PLUGINS_LA)

# nuke everything but the mvm script; plugins.ext and plugins.int are assumed
# to be copied from the parent or grandparent directory

reallyclean:
	for f in *; do case "$$f" in mvm) ;; *) rm -rf $$f; esac; done

# unix launch scripts
squeak.sh: ${cfgdir}/squeak.sh.in getversion
	sed "s|.expanded_relative_imgdir.|lib/squeak/`./getversion VERSION_TAG`|" <${cfgdir}/squeak.sh.in >squeak.sh

bin.squeak.sh: ${cfgdir}/bin.squeak.sh.in getversion
	sed "s|.expanded_relative_imgdir.|lib/squeak/`./getversion VERSION_TAG`|" <${cfgdir}/bin.squeak.sh.in >bin.squeak.sh

# npsqueak

npsqueak : nps/npsqueak.so

nps :
	mkdir nps
	$(SHELL) -ec 'cd nps; ln -s $(topdir)/platforms/unix/npsqueak/* .'

nps/npsqueak.so : nps getversion
	$(SHELL) -ec 'cd nps; $(MAKE) plgdir=$(plgdir) bindir=$(bindir) imgdir=$(imgdir)'

# OSX app bundle

osxdir=$(topdir)/platforms/unix/vm-display-Quartz
#app=Squeak-$(VM_MAJOR).$(VM_MINOR)-$(VM_RELEASE).app
app=Squeak-`./getversion VM_MAJOR`.`./getversion VM_MINOR`-`./getversion VM_RELEASE`.app
appdir=$(app)/Contents

Squeak.app : squeak plugins Info.plist getversion
	/bin/rm -rf $(app)
	mkdir -p			$(appdir)/MacOS
	cp -p  squeak			$(appdir)/MacOS/.
	cp -p  */.libs/*		$(appdir)/MacOS/.
	rm -f				$(appdir)/MacOS/*.la
	rm -f				$(appdir)/MacOS/*.lai
	cp -p  Info.plist		$(appdir)/.
	cp -p  $(osxdir)/PkgInfo	$(appdir)/.
	cp -pr $(osxdir)/Resources	$(appdir)/.
	-find $(app) -name '*~' | xargs rm -f

Info.plist : $(osxdir)/Info.plist.in $(osxdir)/mkinfo getversion
	$(osxdir)/mkinfo $(osxdir)/Info.plist.in Info.plist.tmp "`./getversion VM_VERSION`"
	mv Info.plist.tmp Info.plist

# OSX plugin bundle

nposxdir=$(topdir)/platforms/unix/vm-display-Quartz
npapp=NPSqueak.bundle
npappdir=$(npapp)/Contents

NPSqueak.bundle : NPSqueak plugins
	/bin/rm -rf $(npapp)
	mkdir -p			$(npappdir)/MacOS
	cp -p  squeak			$(npappdir)/MacOS/.
	cp -p  */.libs/*.so		$(npappdir)/MacOS/.
	cp -p  Info.plist		$(npappdir)/.
	cp -p  $(nposxdir)/PkgInfo	$(npappdir)/.
	cp -pr $(nposxdir)/Resources	$(npappdir)/.
	-find $(npapp) -name '*~' | xargs rm -f

NPOBJS		= vm-display-Quartz/sqUnixSafari.o vm-sound-MacOSX/sqUnixSoundMacOSX.o vm-display-Quartz/sqUnixQuartz.o
NPLIBS		= $(NPOBJS) -framework CoreAudio -framework AudioToolbox

NPSqueak : config.sh $(SQLIBS) version.o $(NPOBJS)
	gcc -bundle -flat_namespace -undefined suppress -o NPSqueak \
	  $(NPLIBS) $(SQLIBS) version.o $(LIBS)  vm/vm.a

# manual page

squeak.1 : $(topdir)/platforms/unix/doc/squeak.1 getversion
	$(cfgdir)/mkman `./getversion VM_MAJOR` `./getversion VM_VERSION` \
	  $(bindir) $(imgdir) $(plgdir) $(mandir) $(docdir) \
	  < $(topdir)/platforms/unix/doc/squeak.1 > $@

# install/distrib (these just get in the way -- suck 'em in from elsewhere)

# Makefile.install for Unix Squeak using VMMaker		-*- makefile -*-
# 
# Author: ian.piumarta@inria.fr
# 
# Last edited: 2005-03-22 13:05:47 by piumarta on squeak.hpl.hp.com

DOCFILES	= COPYING COPYRIGHT LICENSE \
		  README.Contributing README.Keyboard README.Sound

ICONS		= $(topdir)/platforms/unix/vm-display-Quartz/Resources/SqueakVM.icns

install : install-squeak install-plugins install-doc $(install_nps)

uninstall : uninstall-squeak uninstall-plugins uninstall-doc $(uninstall_nps)

# squeak

install-squeak : $(squeak) $(squeaksh) $(binsqueaksh) getversion
	$(MKINSTALLDIRS) $(ROOT)$(plgdir)
	$(MKINSTALLDIRS) $(ROOT)$(bindir)
	$(INSTALL_PROG) $(squeak) $(ROOT)$(plgdir)
	$(INSTALL_SCRIPT) $(squeaksh) $(ROOT)$(exec_prefix)/$(squeak)
	$(INSTALL_SCRIPT) $(binsqueaksh) $(ROOT)$(bindir)/$(scriptname)
	if test -n "$(VM_APP_ICONS)"; then \
	  $(INSTALL_DATA) $(ICONS) $(ROOT)$(VM_APP_ICONS); \
	fi

uninstall-squeak : getversion .force
	if test -n "$(VM_APP_ICONS)"; then \
	  $(UNINSTALL) $(ROOT)$(VM_APP_ICONS); \
	fi
	@$(UNINSTALL) $(ROOT)$(plgdir) $(squeak)
	@$(UNINSTALL) $(ROOT)$(bindir) $(scriptname)

# plugins

install-plugins : plugins getversion
	$(MKINSTALLDIRS) $(ROOT)$(plgdir)
	@list='$(PLUGINS_LA)'; for p in $$list; do \
	  if test -f */$$p; then \
	    echo "$(LIBTOOL) --mode=install $(INSTALL_PROG) $$p $(ROOT)$(plgdir)/$$p"; \
	    $(LIBTOOL) --mode=install $(INSTALL_PROG) */$$p $(ROOT)$(plgdir)/$$p; \
	  else :; fi; \
	done
	-rm $(ROOT)$(plgdir)/*.la

uninstall-plugins : getversion .force
	@list='$(PLUGINS_LA)'; for p in $$list; do \
	  filename=$(ROOT)/$(plgdir)/`basename $$p .la`;\
	  if test -f $$filename; then \
	    echo "$(LIBTOOL) --mode=uninstall rm -f $$filename"; \
	    $(LIBTOOL) --mode=uninstall rm -f $$filename; \
	  else
	    echo "$$filename does not exist"; fi; \
	done
	@$(UNINSTALL) $(ROOT)$(plgdir)

# doc

install-doc : squeak.1
	$(MKINSTALLDIRS) $(ROOT)$(docdir)
	@list='$(DOCFILES)'; for f in $$list; do \
	  echo $(INSTALL_DATA) $(topdir)/platforms/unix/doc/$$f $(ROOT)$(docdir); \
	  $(INSTALL_DATA) $(topdir)/platforms/unix/doc/$$f $(ROOT)$(docdir); \
	done
	gzip -f9 $(ROOT)$(docdir)/*
	$(MKINSTALLDIRS) $(ROOT)$(mandir)/man1
	$(INSTALL_DATA) squeak.1 $(ROOT)$(mandir)/man1
	rm -f $(ROOT)$(mandir)/man1/inisqueak.1 $(ROOT)$(mandir)/man1/inisqueak.1.gz
	if test -f $(ROOT)$(mandir)/man1/squeak.1; then $(LN) $(ROOT)$(mandir)/man1/squeak.1 $(ROOT)$(mandir)/man1/inisqueak.1; fi
	if test -f $(ROOT)$(mandir)/man1/squeak.1.gz; then $(LN) $(ROOT)$(mandir)/man1/squeak.1.gz $(ROOT)$(mandir)/man1/inisqueak.1.gz; fi

uninstall-doc :
	@list='$(DOCFILES)'; for f in $$list; do \
	  rm -fv $(ROOT)$(docdir)/$$f.gz; \
	done
	@$(UNINSTALL) $(ROOT)$(docdir) $(DOCFILES)
	@$(UNINSTALL) $(ROOT)$(mandir)/man1 squeak.1 inisqueak.1

# image

install-image : inisqueak $(topdir)/Squeak$(SQ_VERSION).image.gz $(topdir)/Squeak$(SQ_VERSION).changes.gz
	$(MKINSTALLDIRS) $(ROOT)$(imgdir)
	$(INSTALL_PROG) inisqueak $(ROOT)$(imgdir)
	$(INSTALL_DATA) $(topdir)/Squeak$(SQ_VERSION).image.gz $(ROOT)$(imgdir)
	$(INSTALL_DATA) $(topdir)/Squeak$(SQ_VERSION).changes.gz $(ROOT)$(imgdir)
	$(LN_S) Squeak$(SQ_VERSION).image.gz $(ROOT)$(imgdir)/squeak.image.gz
	$(LN_S) Squeak$(SQ_VERSION).changes.gz $(ROOT)$(imgdir)/squeak.changes.gz
	$(MKINSTALLDIRS) $(ROOT)$(bindir)
	( path=`$(cfgdir)/relpath $(bindir) $(imgdir)`; \
	  cd $(ROOT)$(bindir); \
	  rm -f inisqueak; \
	  $(LN_S) $$path/inisqueak .; )

uninstall-image : getversion
	@$(UNINSTALL) $(ROOT)$(plgdir) Squeak$(SQ_VERSION).image.gz
	@$(UNINSTALL) $(ROOT)$(plgdir) Squeak$(SQ_VERSION).changes.gz
	@$(UNINSTALL) $(ROOT)$(plgdir) inisqueak

# sources

install-sources :
	$(MKINSTALLDIRS) $(ROOT)$(imgdir)
	$(INSTALL_DATA) $(topdir)/SqueakV$(SQ_MAJOR).sources $(ROOT)$(imgdir)

uninstall-sources :
	@$(UNINSTALL) $(ROOT)$(imgdir) SqueakV$(SQ_MAJOR).sources

# npsqueak

install-npsqueak : npsqueak getversion .force
	$(SHELL) -ec 'cd nps; $(MAKE) install ROOT=$(ROOT) VM_VERSION=$(VM_VERSION) plgdir=$(plgdir) bindir=$(bindir) imgdir=$(imgdir)'

uninstall-npsqueak : npsqueak getversion .force
	$(SHELL) -ec 'cd nps; $(MAKE) uninstall ROOT=$(ROOT) VM_VERSION=$(VM_VERSION) plgdir=$(plgdir) bindir=$(bindir) imgdir=$(imgdir)'

# VMM configuration changes

config.sh : $(vmmcfg)/plugins.int $(vmmcfg)/plugins.ext libtool
	./config.status
	@echo
	@echo "configuration changed: please run make again"
	@echo
	@exit 1

# bookkeeping
LIBTOOL_DEPS = ../../../../platforms/unix/config/ltmain.sh
libtool: $(LIBTOOL_DEPS)
	$(SHELL) ./config.status libtool


# targets



vm/vm$a : .force
	@$(SHELL) -ec 'cd vm; $(MAKE) vm$a'

ADPCMCodecPlugin/ADPCMCodecPlugin$a : .force
	@$(SHELL) -ec 'cd ADPCMCodecPlugin; $(MAKE) ADPCMCodecPlugin$a'

B2DPlugin/B2DPlugin$a : .force
	@$(SHELL) -ec 'cd B2DPlugin; $(MAKE) B2DPlugin$a'

BitBltPlugin/BitBltPlugin$a : .force
	@$(SHELL) -ec 'cd BitBltPlugin; $(MAKE) BitBltPlugin$a'

BMPReadWriterPlugin/BMPReadWriterPlugin$a : .force
	@$(SHELL) -ec 'cd BMPReadWriterPlugin; $(MAKE) BMPReadWriterPlugin$a'

CroquetPlugin/CroquetPlugin$a : .force
	@$(SHELL) -ec 'cd CroquetPlugin; $(MAKE) CroquetPlugin$a'

HostWindowPlugin/HostWindowPlugin$a : .force
	@$(SHELL) -ec 'cd HostWindowPlugin; $(MAKE) HostWindowPlugin$a'

ZipPlugin/ZipPlugin$a : .force
	@$(SHELL) -ec 'cd ZipPlugin; $(MAKE) ZipPlugin$a'

DropPlugin/DropPlugin$a : .force
	@$(SHELL) -ec 'cd DropPlugin; $(MAKE) DropPlugin$a'

DSAPrims/DSAPrims$a : .force
	@$(SHELL) -ec 'cd DSAPrims; $(MAKE) DSAPrims$a'

FFTPlugin/FFTPlugin$a : .force
	@$(SHELL) -ec 'cd FFTPlugin; $(MAKE) FFTPlugin$a'

FileCopyPlugin/FileCopyPlugin$a : .force
	@$(SHELL) -ec 'cd FileCopyPlugin; $(MAKE) FileCopyPlugin$a'

FilePlugin/FilePlugin$a : .force
	@$(SHELL) -ec 'cd FilePlugin; $(MAKE) FilePlugin$a'

FileDialogPlugin/FileDialogPlugin$a : .force
	@$(SHELL) -ec 'cd FileDialogPlugin; $(MAKE) FileDialogPlugin$a'

Float64ArrayPlugin/Float64ArrayPlugin$a : .force
	@$(SHELL) -ec 'cd Float64ArrayPlugin; $(MAKE) Float64ArrayPlugin$a'

FloatArrayPlugin/FloatArrayPlugin$a : .force
	@$(SHELL) -ec 'cd FloatArrayPlugin; $(MAKE) FloatArrayPlugin$a'

FloatMathPlugin/FloatMathPlugin$a : .force
	@$(SHELL) -ec 'cd FloatMathPlugin; $(MAKE) FloatMathPlugin$a'

IA32ABI/IA32ABI$a : .force
	@$(SHELL) -ec 'cd IA32ABI; $(MAKE) IA32ABI$a'

JPEGReaderPlugin/JPEGReaderPlugin$a : .force
	@$(SHELL) -ec 'cd JPEGReaderPlugin; $(MAKE) JPEGReaderPlugin$a'

JPEGReadWriter2Plugin/JPEGReadWriter2Plugin$a : .force
	@$(SHELL) -ec 'cd JPEGReadWriter2Plugin; $(MAKE) JPEGReadWriter2Plugin$a'

Klatt/Klatt$a : .force
	@$(SHELL) -ec 'cd Klatt; $(MAKE) Klatt$a'

LargeIntegers/LargeIntegers$a : .force
	@$(SHELL) -ec 'cd LargeIntegers; $(MAKE) LargeIntegers$a'

Matrix2x3Plugin/Matrix2x3Plugin$a : .force
	@$(SHELL) -ec 'cd Matrix2x3Plugin; $(MAKE) Matrix2x3Plugin$a'

MiscPrimitivePlugin/MiscPrimitivePlugin$a : .force
	@$(SHELL) -ec 'cd MiscPrimitivePlugin; $(MAKE) MiscPrimitivePlugin$a'

RePlugin/RePlugin$a : .force
	@$(SHELL) -ec 'cd RePlugin; $(MAKE) RePlugin$a'

SecurityPlugin/SecurityPlugin$a : .force
	@$(SHELL) -ec 'cd SecurityPlugin; $(MAKE) SecurityPlugin$a'

SerialPlugin/SerialPlugin$a : .force
	@$(SHELL) -ec 'cd SerialPlugin; $(MAKE) SerialPlugin$a'

SocketPlugin/SocketPlugin$a : .force
	@$(SHELL) -ec 'cd SocketPlugin; $(MAKE) SocketPlugin$a'

SoundCodecPrims/SoundCodecPrims$a : .force
	@$(SHELL) -ec 'cd SoundCodecPrims; $(MAKE) SoundCodecPrims$a'

SoundGenerationPlugin/SoundGenerationPlugin$a : .force
	@$(SHELL) -ec 'cd SoundGenerationPlugin; $(MAKE) SoundGenerationPlugin$a'

SoundPlugin/SoundPlugin$a : .force
	@$(SHELL) -ec 'cd SoundPlugin; $(MAKE) SoundPlugin$a'

StarSqueakPlugin/StarSqueakPlugin$a : .force
	@$(SHELL) -ec 'cd StarSqueakPlugin; $(MAKE) StarSqueakPlugin$a'

SurfacePlugin/SurfacePlugin$a : .force
	@$(SHELL) -ec 'cd SurfacePlugin; $(MAKE) SurfacePlugin$a'

vm-display-null${la} :
	@$(SHELL) -ec 'cd vm-display-null; $(MAKE) vm-display-null${la}'

vm-display-qnxScreen${la} :
	@$(SHELL) -ec 'cd vm-display-qnxScreen; $(MAKE) vm-display-qnxScreen${la}'

vm-sound-null${la} :
	@$(SHELL) -ec 'cd vm-sound-null; $(MAKE) vm-sound-null${la}'

FileAttributesPlugin${la} :
	@$(SHELL) -ec 'cd FileAttributesPlugin; $(MAKE) FileAttributesPlugin${la}'

SqueakFFIPrims${la} :
	@$(SHELL) -ec 'cd SqueakFFIPrims; $(MAKE) SqueakFFIPrims${la}'

LocalePlugin${la} :
	@$(SHELL) -ec 'cd LocalePlugin; $(MAKE) LocalePlugin${la}'

VectorEnginePlugin${la} :
	@$(SHELL) -ec 'cd VectorEnginePlugin; $(MAKE) VectorEnginePlugin${la}'

.force :
