XCPPFLAGS= -I$(topdir)/platforms/Cross/plugins/FilePlugin -I$(topdir)/platforms/Cross/plugins/SocketPlugin
XINCLUDES= $(X_INCLUDES)
XLDFLAGS= $(X_LIBS) -L ../vm-display-X11/.libs -lvm-display-X11
