LIBDEPS=../cpu/libcpu.a
ARMGDB=../../../processors/ARM/gdb-8.3.1
INCLUDES := -I$(ARMGDB)/include \
			-I$(ARMGDB)/sim/common \
			-I$(ARMGDB)/sim/aarch64 \
			-I$(ARMGDB)/bfd \
			-I../bfd -I../gdb -I..
LIBS:=-L../bfd -L../libiberty -L../opcodes -L../sim/aarch64 \
           -lbfd -liberty -lopcodes -lopcodes -lsim -lz
CFLAGS=-m32 -DCOG=1 -DMODET -DWITH_PROFILE=-1 $(INCLUDES) $(LIBS)

GDBARMEXP=.
CLASS=GdbARMv8Alien

.PHONY:	$(LIBDEPS)

all: ${CLASS}-regs.st ${CLASS}-ctrl.st ${CLASS}-vfp.st

${CLASS}-regs.st: printcpu
	./printcpu >${CLASS}-regs.st

${CLASS}-ctrl.st: printcpuctrl
	./printcpuctrl >${CLASS}-ctrl.st

${CLASS}-vfp.st: printcpuvfp
	./printcpuvfp >${CLASS}-vfp.st

clean:
	rm -f ${CLASS}-regs.st ${CLASS}-vfp.st
	rm -f printcpu printcpuctrl printcpuvfp
	rm -f printcpu.exe printcpuctrl.exe printcpuvfp.exe

printcpu: $(GDBARMEXP)/printcpu.c $(LIBDEPS)
	$(CC) -o $@ $< $(CFLAGS)

printcpuctrl: $(GDBARMEXP)/printcpuctrl.c $(LIBDEPS)
	$(CC) -o $@ $< $(CFLAGS)

printcpuvfp: $(GDBARMEXP)/printcpuvfp.c $(LIBDEPS)
	$(CC) -o $@ $< $(CFLAGS)
