XCPPFLAGS= -I$(topdir)/platforms/Cross/plugins/FilePlugin -I$(topdir)/platforms/Cross/plugins/SocketPlugin
XINCLUDES= $(X_INCLUDES)
XLDFLAGS= $(X_LIBS) -L. -lvm-display-X11

$(TARGET):	libvm-display-X11.so

# note the test below is for handling broken libtool that don't generate the .so extension
libvm-display-X11.so:
	test -e ../vm-display-X11/.libs/vm-display-X11 && $(LN_S) ../vm-display-X11/.libs/vm-display-X11 libvm-display-X11.so || $(LN_S) ../vm-display-X11/.libs/vm-display-X11.so libvm-display-X11.so
