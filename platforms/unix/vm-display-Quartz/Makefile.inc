XCPPFLAGS=	-I$(topdir)/platforms/Cross/plugins/B3DAcceleratorPlugin \
		-I$(topdir)/platforms/unix/plugins/B3DAcceleratorPlugin \
		-framework Cocoa -framework OpenGL

PLIBS=		-Wl,-framework -Wl,Cocoa \
		-Wl,-framework -Wl,OpenGL
