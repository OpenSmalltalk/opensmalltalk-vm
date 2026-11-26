GDBBUILDFOLDER	= ../../../gdbriscv64
GDBSOURCEFOLDER	= ../../../../processors/RiscV64/gdb-18.1

XINCLUDES	+= -I$(GDBSOURCEFOLDER)/include
XINCLUDES	+= -I$(GDBSOURCEFOLDER)/sim/riscv

XLDFLAGS=	$(GDBBUILDFOLDER)/sim/riscv/libsim.a \
			$(GDBBUILDFOLDER)/opcodes/libopcodes.a \
			-lbfd -liberty \
			-Wl
