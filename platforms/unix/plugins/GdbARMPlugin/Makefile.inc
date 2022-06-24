GDBBUILDFOLDER	= ../../../gdbarm32
GDBSOURCEFOLDER	= $(topdir)/processors/ARM/gdb-8.3.1

XCFLAGS	:= -I. # because the build directory's config.h must be included first
XCFLAGS	+= -I$(GDBSOURCEFOLDER)/include
XCFLAGS	+= -I$(GDBSOURCEFOLDER)/sim/arm
XCFLAGS	+= -I$(GDBSOURCEFOLDER)
XCFLAGS	+= -I$(GDBBUILDFOLDER)

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/arm/libsim.a \
			$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
			-lbfd -liberty \
			-Wl
