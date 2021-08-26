#############################################################################
# Makefile for Win32 Stack Spur PharoVM using cygwin
# Do make init to allow make -n to function.
#############################################################################

VM:=Pharo
VM_NAME:=Pharo Virtual Machine

VMSRCDIR:=../../../src/spur64.stack
COGDEFS:= -DPharoVM=1

THIRDPARTYLIBS:=pkgconfig openssl libssh2 libgit2 libsdl2 zlib libpng freetype2 pixman cairo libgcc

include ../common/Makefile

# third-party libraries
#
include ../third-party/Makefile.pkgconfig
include ../third-party/Makefile.freetype2
include ../third-party/Makefile.openssl.win64
include ../third-party/Makefile.libssh2
include ../third-party/Makefile.libgit2
include ../third-party/Makefile.libsdl2
include ../third-party/Makefile.zlib
include ../third-party/Makefile.pixman
include ../third-party/Makefile.libpng
include ../third-party/Makefile.cairo
include ../third-party/Makefile.libgcc

# Since SDLDisplayPlugin will be included as internal plugin, we need to add the library to the path
# add to the end to allow thirdparty vars to be defined.
STDLIBS+= -L$(THIRDPARTYOUTDIR)/lib -lSDL2
