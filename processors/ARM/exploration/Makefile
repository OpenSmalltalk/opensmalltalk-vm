LIBDEPS=../cpu/libcpu.a
GDBARM=../../../processors/ARM/gdb-7.10
GDBARMEXP=.
INCLUDES := -I$(GDBARM)/include \
			-I$(GDBARM)/sim/arm \
			-I$(GDBARM)/bfd \
			-I../bfd
LIBS:=-L../bfd -L../libiberty -L../opcodes -L../sim/arm -L../zlib \
           -lbfd -liberty -lopcodes -lopcodes -lsim -lz
CFLAGS=-m32 -DMODET $(INCLUDES) $(LIBS)

.PHONY:	$(LIBDEPS)

all: GdbARMAlien-regs.st GdbARMAlien-vfp.st

GdbARMAlien-regs.st: printcpu
	./printcpu >GdbARMAlien-regs.st

GdbARMAlien-vfp.st: printcpuvfp
	./printcpuvfp >GdbARMAlien-vfp.st

clean:
	rm -f GdbARMAlien-regs.st GdbARMAlien-vfp.st
	rm -f printcpu printcpuvfp
	rm -f printcpu.exe printcpuvfp.exe

printcpu: $(GDBARMEXP)/printcpu.c $(LIBDEPS)
	$(CC) -o $@ $< $(CFLAGS)

printcpuvfp: $(GDBARMEXP)/printcpuvfp.c $(LIBDEPS)
	$(CC) -o $@ $< $(CFLAGS)
