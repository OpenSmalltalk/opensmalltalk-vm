ifndef THIRDPARTYDIR
	include ../common/Makefile.lib.extra
endif
include ../../third-party/cairo.spec

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

# IMPORTANT: This hack of "echo..." is needed to properly compile cairo. 
# this is a long time error reported by Igor a lot of time ago: 
# https://lists.cairographics.org/archives/cairo/2012-October/023675.html
# nobody answered his concern at the time and today (version 1.14.6), 
# this is still not solved. 
$(THIRDPARTYLIBDIR)/$(CAIROLIBNAME): $(CAIROARCHIVE)
	tar x -f $(CAIROARCHIVE) -C $(THIRDPARTYDIR)
	cd $(CAIRODIR) \
		&& ./configure \
			--prefix="$(THIRDPARTYOUTDIR)" \
			PKG_CONFIG="$(PKG_CONFIG)" \
			PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
			CFLAGS='$(THIRDPARTY_CFLAGS) -I$(THIRDPARTYINCLUDEDIR) -march=pentium4' \
			LDFLAGS='$(THIRDPARTY_LDFLAGS) -L$(THIRDPARTYLIBDIR) -march=pentium4' \
			--disable-silent-rules \
			--disable-xlib \
			--disable-dependency-tracking \
		&& echo "#define _SSIZE_T_DEFINED 1" >> config.h \
		&& make \
		&& make install

$(CAIROLIB): pkgconfig libpng freetype2 pixman $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME)
	cp -f $(THIRDPARTYLIBDIR)/$(CAIROLIBNAME) $(THIRDPARTYINSTALLDIR)
	
cairo: $(CAIROLIB)