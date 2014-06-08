include ../../Makefile.plugin

# On Cog we use the ThreadedFFIPlugin and need no platform-dependent code
ifdef COGDEFS
MAKERSRC:=$(MAKERDIR)/SqueakFFIPrims.c
LIBSRC:= $(notdir $(MAKERSRC) $(CROSSSRC))
endif
