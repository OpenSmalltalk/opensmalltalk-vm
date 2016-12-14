ifndef THIRDPARTYDIR
	include ../common/Makefile.lib.extra
endif
include ../../third-party/cairo.spec

# plugin definitions
CAIROURL:=$(cairo_spec_download_url)
CAIROLIBNAME:=$(cairo_spec_product_name_macOS)
CAIRODIR:=$(THIRDPARTYDIR)/$(cairo_spec_unpack_dir_name)
CAIROARCHIVE:=$(THIRDPARTYCACHEDIR)/$(cairo_spec_archive_name)
CAIROLIB:=$(THIRDPARTYINSTALLDIR)/$(CAIROLIBNAME)
CAIROSYMLINKS=$(cairo_spec_symlinks_macOS)

# ensure third-party library is built and recognised by plugins
INCDIRS:=$(INCDIRS) $(THIRDPARTYINCLUDEDIR)
EXTRALIBS:=$(EXTRALIBS) $(CAIROLIB)
PLUGINREQS:=$(THIRDPARTYLIBS)

$(CAIROARCHIVE): 
	curl -o $(CAIROARCHIVE) -L $(CAIROURL) 

$(THIRDPARTYLIBDIR)/$(CAIROLIBNAME): $(CAIROARCHIVE)
	tar x -f $(CAIROARCHIVE) -C $(THIRDPARTYDIR)
	cd $(CAIRODIR) \
		&& ./configure \
			--prefix="$(THIRDPARTYOUTDIR)" \
			PKG_CONFIG="$(PKG_CONFIG)" \
			PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
			CFLAGS='-arch x86_64' \
			LDFLAGS='-arch x86_64' \
			--disable-silent-rules \
			--disable-xlib \
			--disable-dependency-tracking \
		&& make \
		&& make install

$(CAIROLIB): pkgconfig libpng freetype2 pixman $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME)
	cp -f $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME) $(THIRDPARTYINSTALLDIR)
	install_name_tool -id "@executable_path/Plugins/$(CAIROLIBNAME)" $(CAIROLIB)
	@echo "Installing links"
	@for each in $(THIRDPARTYLIBDIR)/$(CAIROSYMLINKS); do \
		if [ -L $$each ]; then \
			cp -a $$each $(THIRDPARTYINSTALLDIR); \
		fi \
	done
	@echo "Fixing dependency links"
	@for each in $(PIXMANLIBNAME) $(FREETYPE2LIBNAME) $(LIBPNGLIBNAME); do \
		install_name_tool -change "$(THIRDPARTYLIBDIR)/$$each" "@executable_path/Plugins/$$each" $(CAIROLIB); \
	done
	@echo "DONE"
	
cairo: $(CAIROLIB)