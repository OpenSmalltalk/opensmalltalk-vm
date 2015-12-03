#LIBDEPS=../../bochs/cpu/libcpu.a
#BOCHS=../../bochs
#BOCHSEXP=../../bochs/exploration
LIBDEPS=../cpu/libcpu.a
BOCHS=../../../processors/IA32/bochs
BOCHSEXP=.
CFLAGS=-m32 -I.. -I$(BOCHS) -I$(BOCHS)/cpu -I$(BOCHS)/instrument/stubs -L../cpu -lcpu

.PHONY:	$(LIBDEPS)

#all: bxcpu.txt BochsIA32Alien-regs.st BochsIA32Alien-cr.st BochsIA32Alien-xmm.st
all: BochsIA32Alien-regs.st BochsIA32Alien-cr.st BochsIA32Alien-xmm.st

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

printbxcpu: $(BOCHSEXP)/printbxcpu.cpp $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpu: $(BOCHSEXP)/printcpu.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpucr: $(BOCHSEXP)/printcpucr.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpuxmm: $(BOCHSEXP)/printcpuxmm.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)
