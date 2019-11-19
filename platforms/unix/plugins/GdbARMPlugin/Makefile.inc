GDBBUILDFOLDER	= ../../../gdbarm32
GDBSOURCEFOLDER	= ../../../../processors/ARM/gdb-7.10/

XINCLUDES	+= -I$(GDBSOURCEFOLDER)/include
XINCLUDES	+= -I$(GDBSOURCEFOLDER)/sim/arm

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/arm/libsim.a \
			$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
			-lbfd -liberty \
			-Wl
