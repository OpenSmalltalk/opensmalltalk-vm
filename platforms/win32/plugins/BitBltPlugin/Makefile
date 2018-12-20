# Override to avoid files in platforms/Cross/plugins/BitBltPlugin.
# Fails if one redefines VPATH and then includes ../../Makefile.plugin.  Grrr...

WIN32DIR:=	$(PLATDIR)/win32/plugins/$(LIBNAME)
MAKERDIR:=	$(PLUGINSRCDIR)/plugins/$(LIBNAME)
OBJDIR:=    $(BASEDIR)/$(BUILD)/$(LIBNAME)

%:
	$(MAKE) -f ../../Makefile.plugin VPATH="$(MAKERDIR) $(WIN32DIR) $(OBJDIR)" \
				CROSSSRC="" $@
