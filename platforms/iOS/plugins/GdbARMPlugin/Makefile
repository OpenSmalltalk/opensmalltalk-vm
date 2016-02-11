INCDIRS:=../../processors/ARM/gdb-7.10/include \
         ../../processors/ARM/gdb-7.10/sim/arm \
         ../../processors/ARM/gdb-7.10/bfd \
         ../gdbarm32/bfd
INCFIRST:=../../processors/ARM/gdb-7.10/include \
          ../../processors/ARM/gdb-7.10/sim/arm \
          ../../processors/ARM/gdb-7.10/bfd \
          ../gdbarm32/bfd
EXTRALIBS:=-L../gdbarm32/bfd -L../gdbarm32/libiberty -L../gdbarm32/opcodes \
           -L../gdbarm32/sim/arm -L../gdbarm32/zlib \
           -lbfd -liberty -lopcodes -lopcodes -lsim -lz

include ../common/Makefile.plugin

INCDIRS:= $(INCFIRST) $(MAKERVMDIR) $(CROSSVMDIR) $(MAKERDIR) $(OSXPLGDIR) $(OSXVMDIR) $(CROSSDIR)
INCLUDES:= $(addprefix -I,. $(INCDIRS))
