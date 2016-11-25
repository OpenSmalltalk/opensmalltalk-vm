#############################################################################
# Makefile for Win32 Cog Spur PharoVM using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

VM:=Pharo
VM_NAME:=Pharo Virtual Machine

VMSRCDIR:=../../spursrc/vm
COGDEFS:= -DPharoVM=1 -DIMMUTABILITY=1

THIRDPARTYLIBS:=pkgconfig openssl libssh2 libgit2 libsdl2 zlib libpng freetype2 pixman cairo
	
include ../common/Makefile

# third-party libraries
#
include ../third-party/pkgconfig/Makefile.lib
include ../third-party/freetype2/Makefile.lib
include ../third-party/openssl/Makefile.lib
include ../third-party/libssh2/Makefile.lib
include ../third-party/libgit2/Makefile.lib
include ../third-party/libsdl2/Makefile.lib
include ../third-party/zlib/Makefile.lib
include ../third-party/pixman/Makefile.lib
include ../third-party/libpng/Makefile.lib
include ../third-party/cairo/Makefile.lib

# Since SDLDisplayPlugin will be included as internal plugin, we need to add the library to the path
# add to the end to allow thirdparty vars to be defined.
STDLIBS+= -L$(THIRDPARTYOUTDIR)/lib -lSDL2