GDBBUILDFOLDER	= ../../../gdbarm64
GDBSOURCEFOLDER	= ../../../../processors/ARM/gdb-8.3.1
XCFLAGS		= -DNEED_UI_LOOP_HOOK

XINCLUDES	+= -I$(GDBSOURCEFOLDER)/include
XINCLUDES	+= -I$(GDBSOURCEFOLDER)/sim/aarch64

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/aarch64/libsim.a \
			$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
			-lbfd -liberty \
			-Wl
