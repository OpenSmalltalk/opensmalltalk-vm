# Preamble: include third-party common definitions and library to require
include ../common/Makefile.extra
include ../third-party/freetype2/Makefile.lib

# NOTE: I need to use src dir for include because install is not copying them correctly
INCDIRS:=$(INCDIRS) $(FREETYPE2DIR)/include
EXTRALIBS:=$(EXTRALIBS) $(FREETYPE2LIB)
THIRDPARTYLIBS:=$(FREETYPE2LIB)
PLUGINREQS:=$(THIRDPARTYLIBS)

include ../common/Makefile.plugin
