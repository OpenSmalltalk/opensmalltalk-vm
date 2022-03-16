GDB=../../../processors/ARM/gdb-8.3.1
PREREQUISITES:= ../gdbarm64/bfd/libbfd.a \
				../gdbarm64/libiberty/libiberty.a \
				../gdbarm64/opcodes/libopcodes.a \
				../gdbarm64/sim/aarch64/libsim.a

INCDIRS:=$(GDB)/include $(GDB)/opcodes $(GDB)/sim/aarch64 $(GDB)/sim/common $(GDB)/bfd ../gdbarm64/bfd ../gdbarm64/sim
INCFIRST:=$(GDB)/include $(GDB)/opcodes $(GDB)/sim/aarch64 $(GDB)/sim/common $(GDB)/bfd ../gdbarm64/bfd ../gdbarm64/sim
XCFLAGS:=-DWITH_PROFILE=-1

# assert uses warning, which is in the VM, so -undefined dynamic_lookup needed
ifeq ($(CONFIGURATION),assert)
    EXTRA_FOR_ASSERT:=-undefined dynamic_lookup
else ifeq ($(CONFIGURATION),debug)
    EXTRA_FOR_ASSERT:=-undefined dynamic_lookup
    BUILD:=builddbg 
else # default CONFIGURATION=product
    EXTRA_FOR_ASSERT:=
endif 
EXTRALIBS:= -L../gdbarm64/bfd -L../gdbarm64/libiberty \
			-L../gdbarm64/opcodes -L../gdbarm64/sim/aarch64 \
			-lbfd -liberty -lopcodes -lopcodes -lsim -lz \
			$(EXTRA_FOR_ASSERT)

include ../common/Makefile.plugin

INCDIRS:= $(INCFIRST) $(MAKERVMDIR) $(CROSSVMDIR) $(MAKERDIR) $(OSXPLGDIR) $(OSXVMDIR) $(CROSSDIR)
INCLUDES:= $(addprefix -I,. $(INCDIRS))
