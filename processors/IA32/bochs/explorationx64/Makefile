#LIBDEPS=../../bochs/cpu/libcpu.a
#BOCHS=../../bochs
#BOCHSEXP=../../bochs/exploration
#BOCHS=../../../processors/IA32/bochs
#BOCHSEX64=$(BOCHS)/explorationx64
BOCHS=../../../processors/IA32/bochs
BOCHSEX64=.
LIBDEPS=../../cpu/libcpu.a
CFLAGS=-m32 -I.. -I$(BOCHS) -I$(BOCHS)/cpu -I$(BOCHS)/instrument/stubs -L../cpu -lcpu
FULLLIBS=-L../fpu -lfpu -L../disasm -ldisasm

.PHONY:	$(LIBDEPS)

all: BochsX64Alien-regs.st BochsX64Alien-cr.st BochsX64Alien-xmm.st

BochsX64Alien-regs.st: printcpu
	./printcpu >BochsX64Alien-regs.st

BochsX64Alien-cr.st: printcpucr
	./printcpucr >BochsX64Alien-cr.st

BochsX64Alien-xmm.st: printcpuxmm
	./printcpuxmm >BochsX64Alien-xmm.st

clean:
	rm -f BochsX64Alien-regs.st BochsX64Alien-cr.st BochsX64Alien-xmm.st
	rm -f printcpu printcpucr printcpuxmm
	rm -f printcpu.exe printcpucr.exe printcpuxmm.exe

printcpu: $(BOCHSEX64)/printcpu.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpucr: $(BOCHSEX64)/printcpucr.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpuxmm: $(BOCHSEX64)/printcpuxmm.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)
