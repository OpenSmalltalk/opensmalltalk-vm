GDB=../../../processors/ARM/gdb-8.3.1
PREREQUISITES:= ../gdbarm64/bfd/libbfd.a \
				../gdbarm64/libiberty/libiberty.a \
				../gdbarm64/opcodes/libopcodes.a \
				../gdbarm64/sim/aarch64/libsim.a

INCDIRS:=$(GDB)/include $(GDB)/opcodes $(GDB)/sim/aarch64 $(GDB)/sim/common $(GDB)/bfd ../gdbarm64/bfd ../gdbarm64/sim
INCFIRST:=$(GDB)/include $(GDB)/opcodes $(GDB)/sim/aarch64 $(GDB)/sim/common $(GDB)/bfd ../gdbarm64/bfd ../gdbarm64/sim
XCFLAGS:=-DWITH_PROFILE=-1

EXTRALIBS:= -L../gdbarm64/bfd -L../gdbarm64/libiberty \
			-L../gdbarm64/opcodes -L../gdbarm64/sim/aarch64 \
			-lbfd -liberty -lopcodes -lsim -lz

include ../common/Makefile.plugin

INCDIRS:= $(INCFIRST) $(MAKERVMDIR) $(CROSSVMDIR) $(MAKERDIR) $(OSXPLGDIR) $(OSXVMDIR) $(CROSSDIR)
INCLUDES:= $(addprefix -I,. $(INCDIRS))
