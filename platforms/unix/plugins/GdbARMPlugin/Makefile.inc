# edit this to suit your system; it really ought to use relative paths
# or some other convenience
GDBBUILDFOLDER	= /mnt/hgfs/tim/Documents/Squeak/Rasbian-VM/gdb-7.6
XCFLAGS		= -m32 -DNEED_UI_LOOP_HOOK

XINCLUDES	+= -I$(GDBBUILDFOLDER)/include
XINCLUDES	+= -I$(GDBBUILDFOLDER)/sim/arm
# XINCLUDES	:= -I$(GDBBUILDFOLDER)/bfd $(XINCLUDES)

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/arm/libsim.a \
		$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
		-lbfd -liberty \
		-Wl,-wrap,ARMul_OSHandleSWI
