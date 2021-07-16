# Instead build, copy dependency from mingw distribution

ifndef THIRDPARTYDIR
	include ../common/Makefile.lib.extra
endif
include ../../../third-party/cairo.spec

MINGWLIBDIR:=/usr/x86_64-w64-mingw32/sys-root/mingw/bin
CAIROLIBNAME:=$(cairo_spec_product_name_windows)
CAIROLIB:=$(THIRDPARTYINSTALLDIR)/$(CAIROLIBNAME)
CAIRODEPS:= libfontconfig-1.dll libexpat-1.dll libbz2-1.dll

$(CAIROLIB): pkgconfig libpng freetype2 pixman $(MINGWLIBDIR)/$(CAIROLIBNAME)
	cp -f $(MINGWLIBDIR)/$(CAIROLIBNAME) $(THIRDPARTYINSTALLDIR)
	for each in $(CAIRODEPS); do \
		cp -f $(MINGWLIBDIR)/$$each $(THIRDPARTYINSTALLDIR); \
	done
	
cairo: $(CAIROLIB)