LIBDEPS=../../bochs/cpu/libcpu.a
CFLAGS=-m32 -I.. -I../../bochs -I../../bochs/cpu -I../../bochs/instrument/stubs -L../cpu -lcpu
FULLLIBS=-L../fpu -lfpu -L../disasm -ldisasm

.PHONY:	$(LIBDEPS)

all: bxcpu.txt BochsIA32Alien-regs.st BochsIA32Alien-cr.st BochsIA32Alien-xmm.st

bxcpu.txt: printbxcpu
	./printbxcpu >bxcpu.txt

BochsIA32Alien-regs.st: printcpu
	./printcpu >BochsIA32Alien-regs.st

BochsIA32Alien-cr.st: printcpucr
	./printcpucr >BochsIA32Alien-cr.st

BochsIA32Alien-xmm.st: printcpuxmm
	./printcpuxmm >BochsIA32Alien-xmm.st

clean:
	rm -f BochsIA32Alien-regs.st BochsIA32Alien-cr.st BochsIA32Alien-xmm.st
	rm -f printcpu printcpucr printcpuxmm
	rm -f printcpu.exe printcpucr.exe printcpuxmm.exe

printbxcpu: ../../bochs/exploration/printbxcpu.cpp $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpu: ../../bochs/exploration/printcpu.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpucr: ../../bochs/exploration/printcpucr.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpuxmm: ../../bochs/exploration/printcpuxmm.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)
