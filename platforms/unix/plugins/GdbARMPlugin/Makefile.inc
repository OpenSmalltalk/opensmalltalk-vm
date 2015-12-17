GDBBUILDFOLDER	= ../../../gdbarm32
GDBSOURCEFOLDER	= ../../../../processors/ARM/gdb-7.10/
XCFLAGS		= -m32 -DNEED_UI_LOOP_HOOK

XINCLUDES	+= -I$(GDBSOURCEFOLDER)/include
XINCLUDES	+= -I$(GDBSOURCEFOLDER)/sim/arm

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/arm/libsim.a \
			$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
			-lbfd -liberty \
			-Wl
