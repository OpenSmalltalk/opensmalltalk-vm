##############################################################################
# Makefile for Mac OS X Cog Spur Pharo Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

VMSRCDIR:=../../spursrc/vm
VM:=Pharo
COGDEFS:= -DPharoVM=1 -DIMMUTABILITY=1
APPNAME:=Pharo
APPNAMEDEF:=$(APPNAME)
APPIDENTIFIER:=org.pharo.$(APPNAME)
USEPLUGINASDYLIB:=TRUE
THIRDPARTYLIBS:=pkgconfig zlib libpng freetype2 openssl libssh2 libgit2 libsdl2 pixman cairo
EXTRAVMLIBS=libsdl2	

.PHONY: pkgconfig zlib libpng freetype2 openssl libssh2 libgit2 libsdl2 pixman cairo

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common.minheadless/Makefile.app

# third-party libraries
#
include ../third-party/Makefile.pkgconfig
include ../third-party/Makefile.zlib
include ../third-party/Makefile.libpng
include ../third-party/Makefile.freetype2
include ../third-party/Makefile.openssl
include ../third-party/Makefile.libssh2
include ../third-party/Makefile.libgit2
include ../third-party/Makefile.libsdl2
include ../third-party/Makefile.pixman
include ../third-party/Makefile.cairo

# extras for headless VM to open world with SDL2
# 
CFLAGS+= -I$(THIRDPARTYINCLUDEDIR)/SDL2 -DHAVE_SDL2=1
LDFLAGS+= -L$(THIRDPARTYOUTDIR)/lib -lSDL2
