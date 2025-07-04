GDB=../../../processors/ARM/gdb-8.3.1
PREREQUISITES:= ../gdbarm32/bfd/libbfd.a \
				../gdbarm32/libiberty/libiberty.a \
				../gdbarm32/opcodes/libopcodes.a \
				../gdbarm32/sim/arm/libsim.a

INCFIRST:=$(GDB)/include $(GDB)/sim/arm $(GDB)/bfd ../gdbarm32/bfd $(GDB) ../gdbarm32

EXTRALIBS:= -Wl,-warn_commons,-u,_minReadAddress,-u,_minWriteMaxExecuteAddress \
			-L../gdbarm32/bfd -L../gdbarm32/libiberty \
			-L../gdbarm32/opcodes -L../gdbarm32/sim/arm \
			-lbfd -liberty -lopcodes -lsim -lz

include ../common/Makefile.plugin

INCDIRS:= $(INCFIRST) $(MAKERVMDIR) $(CROSSVMDIR) $(MAKERDIR) $(OSXPLGDIR) $(OSXVMDIR) $(CROSSDIR)
INCLUDES:= $(addprefix -I,. $(INCDIRS))
