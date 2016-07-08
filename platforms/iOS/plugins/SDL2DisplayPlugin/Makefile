# Preamble: include third-party common definitions and library to require
include ../common/Makefile.extra
include ../third-party/libsdl2/Makefile.lib

INCDIRS:=$(THIRDPARTYOUTDIR)/include
EXTRALIBS:=-undefined dynamic_lookup $(LIBSDL2LIB)
THIRDPARTYLIBS:=$(LIBSDL2LIB)
PLUGINREQS:=$(THIRDPARTYLIBS)

include ../common/Makefile.plugin