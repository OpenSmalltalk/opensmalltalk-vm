# This assumes you untar the gdb 7.6 source in processors/ARM/gdb-7.6/
GDBBUILDFOLDER	= ../../../../processors/ARM/gdb-7.6/
XCFLAGS		= -m32 -DNEED_UI_LOOP_HOOK

XINCLUDES	+= -I$(GDBBUILDFOLDER)/include
XINCLUDES	+= -I$(GDBBUILDFOLDER)/sim/arm

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/arm/libsim.a \
		$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
		-lbfd -liberty \
		-Wl,-wrap,ARMul_OSHandleSWI
