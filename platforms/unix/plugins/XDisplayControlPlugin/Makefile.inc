XCPPFLAGS= -I$(topdir)/platforms/Cross/plugins/FilePlugin -I$(topdir)/platforms/Cross/plugins/SocketPlugin
XINCLUDES= $(X_INCLUDES)
XLDFLAGS= $(X_LIBS) -L. -lvm-display-X11

$(TARGET):	libvm-display-X11.so

libvm-display-X11.so:
	ln -s ../vm-display-X11/.libs/vm-display-X11.so libvm-display-X11.so
