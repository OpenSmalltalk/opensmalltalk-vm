ifeq ($(VM),Pharo)
	include ../common/Makefile.lib.extra
	EXTRALIBS:=	-framework CoreFoundation -framework Security -L$(THIRDPARTYINSTALLDIR) -lssl -lcrypto
	THIRDPARTYLIBS:=openssl
	include ../third-party/Makefile.openssl
else
	EXTRALIBS:=	-framework CoreFoundation -framework Security -lssl -lcrypto
endif
include ../common/Makefile.plugin
