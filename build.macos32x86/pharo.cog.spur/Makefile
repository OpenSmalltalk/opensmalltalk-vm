##############################################################################
# Makefile for Mac OS X Cog Spur Pharo Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

VMSRCDIR:=../../src/vm
PLUGINSRCDIR:=../../src/plugins
VM:=Pharo
COGDEFS:=-DPharoVM=1
APPNAME:=Pharo
APPNAMEDEF:=$(APPNAME)
USEPLUGINASDYLIB:=TRUE
THIRDPARTYLIBS:=libssh2 libgit2 pkgconfig pixman libpng cairo

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app

# third-party libraries
#
# include ../third-party/freetype2/Makefile.lib # this is already there because of the dependency on FT2Plugin
include ../third-party/libssh2/Makefile.lib
include ../third-party/libgit2/Makefile.lib
include ../third-party/pkgconfig/Makefile.lib
include ../third-party/pixman/Makefile.lib
include ../third-party/libpng/Makefile.lib
include ../third-party/cairo/Makefile.lib
