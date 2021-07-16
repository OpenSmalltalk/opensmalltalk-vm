ifndef THIRDPARTYDIR
	include ../common/Makefile.lib.extra
endif
include ../../../third-party/cairo.spec

# plugin definitions
CAIROURL:=$(cairo_spec_download_url)
CAIROLIBNAME:=$(cairo_spec_product_name_windows)
CAIRODIR:=$(THIRDPARTYDIR)/$(cairo_spec_unpack_dir_name)
CAIROARCHIVE:=$(THIRDPARTYCACHEDIR)/$(cairo_spec_archive_name)
CAIROLIB:=$(THIRDPARTYINSTALLDIR)/$(CAIROLIBNAME)
	
# ensure third-party library is built and recognised by plugins
INCDIRS:=$(INCDIRS) $(THIRDPARTYINCLUDEDIR)
EXTRALIBS:=$(EXTRALIBS) $(CAIROLIB)
PLUGINREQS:=$(THIRDPARTYLIBS)

$(CAIROARCHIVE): 
	$(WGET) -O $(CAIROARCHIVE) $(CAIROURL) 

# IMPORTANT: The hack for editing test/Makefile after ./configure
# is required on cygwin because it fails to truncate the file
#       test/cairo-test-constructors.c
# when it overwrites it, causing compilation to fail on trailing lines
# We thus add a rule for removing the file before generating it if it exists
# sed '/pattern/i newLine'
# This works in version 1.14.28 but somehow fragile.
# If this cygwin bug is confirmed, the line should be added to Makefile.am
# and any other relevant file, and the change pushed back to cairo repository.
$(THIRDPARTYLIBDIR)/$(CAIROLIBNAME): $(CAIROARCHIVE)
	tar x -f $(CAIROARCHIVE) -C $(THIRDPARTYDIR)
	cd $(CAIRODIR) \
		&& ./configure \
			--prefix="$(THIRDPARTYOUTDIR)" \
			--host=i686-w64-mingw32 \
			PKG_CONFIG="$(PKG_CONFIG)" \
			PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
			CFLAGS='$(THIRDPARTY_CFLAGS) -I$(THIRDPARTYINCLUDEDIR) -march=pentium4' \
			LDFLAGS='$(THIRDPARTY_LDFLAGS) -L$(THIRDPARTYLIBDIR) -march=pentium4' \
			FREETYPE_LIBS="-L$(THIRDPARTYLIBDIR) -lfreetype -lz" \
			FREETYPE_CFLAGS="-I$(THIRDPARTYINCLUDEDIR) -I$(THIRDPARTYINCLUDEDIR)/freetype2" \
			--disable-silent-rules \
			--disable-xlib \
			--disable-dependency-tracking \
		&& sed -i '/.* sh .\/make-/i\\ttest -e \$$\@ \&\& rm \$$\@' test/Makefile \
		&& make \
		&& make install

$(CAIROLIB): pkgconfig libpng freetype2 pixman $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME)
	cp -f $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME) $(THIRDPARTYINSTALLDIR)
	
cairo: $(CAIROLIB)