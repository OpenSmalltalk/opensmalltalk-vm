#############################################################################
# Makefile for Win32 Cog Spur PharoVM using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

VM:=Pharo
VM_NAME:=Pharo Virtual Machine

VMSRCDIR:=../../spursrc/vm
# NOTES: 
# STACK_ALIGN_BYTES=16 is needed in mingw and FFI (and I suppose on other modules too).
# ALLOCA_LIES_SO_USE_GETSP=0 Some compilers return the stack address+4 on alloca function, 
# then FFI module needs to adjust that. It is NOT the case of mingw.
# For more information see this thread: http://forum.world.st/There-are-something-fishy-with-FFI-plugin-td4584226.html
#COGDEFS:= -DPharoVM=1 -DIMMUTABILITY=1 -DSTACK_ALIGN_BYTES=16 -DALLOCA_LIES_SO_USE_GETSP=0
COGDEFS:= -DPharoVM=1 -DIMMUTABILITY=1

THIRDPARTYLIBS:=pkgconfig openssl libssh2 libgit2 libsdl2 zlib libpng freetype2 pixman cairo libgcc
	
include ../common/Makefile

# third-party libraries
#
include ../third-party/Makefile.pkgconfig
include ../third-party/Makefile.freetype2
include ../third-party/Makefile.openssl
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