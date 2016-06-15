# On Cog we use the ThreadedFFIPlugin and need no platform-dependent code
ifdef COGDEFS
CROSSDIR:=	$(PLATDIR)/Cross/plugins/$(LIBNAME)
MAKERDIR:=	$(PLUGINSRCDIR)/plugins/$(LIBNAME)
OBJDIR:=    $(BASEDIR)/$(BUILD)/$(LIBNAME)
WIN32DIR:=	$(PLATDIR)/win32/plugins/$(LIBNAME)

%:
	$(MAKE) -f ../../Makefile.plugin VPATH="$(CROSSDIR) $(MAKERDIR) $(WIN32DIR) $(OBJDIR)" \
		CROSSSRC="sqFFIPlugin.c sqFFITestFuncs.c sqManualSurface.c" \
		MAKERSRC="SqueakFFIPrims.c" \
		WIN32SRC="" \
		$@
else
include ../../Makefile.plugin
endif
