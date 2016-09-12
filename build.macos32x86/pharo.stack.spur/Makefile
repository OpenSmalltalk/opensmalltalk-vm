##############################################################################
# Makefile for Mac OS X Cog Spur Pharo Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

VMSRCDIR:=../../spurstacksrc/vm
PLUGINSRCDIR:=../../spurstacksrc/plugins
VM:=Pharo
COGDEFS:=-DPharoVM=1
APPNAME:=Pharo
APPNAMEDEF:=$(APPNAME)
USEPLUGINASDYLIB:=TRUE
THIRDPARTYLIBS:=pkgconfig freetype2 libssh2 libgit2 pixman libpng cairo

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app

# third-party libraries
#
include ../third-party/pkgconfig/Makefile.lib
include ../third-party/freetype2/Makefile.lib
include ../third-party/libssh2/Makefile.lib
include ../third-party/libgit2/Makefile.lib
include ../third-party/pixman/Makefile.lib
include ../third-party/libpng/Makefile.lib
include ../third-party/cairo/Makefile.lib
