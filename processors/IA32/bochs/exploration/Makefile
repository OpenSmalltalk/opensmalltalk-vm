BOCHS=../../../processors/IA32/bochs
BOCHSEXP=$(BOCHS)/exploration
LIBDEPS=../cpu/libcpu.a
CFLAGS=-m32 -DCOG=1 -I.. -I$(BOCHS) -I$(BOCHS)/cpu -I$(BOCHS)/instrument/stubs -L../cpu -lcpu

.PHONY:	$(LIBDEPS)

CLASS=BochsIA32Alien

all: $(CLASS)-regs.st $(CLASS)-cr.st $(CLASS)-xmm.st

$(CLASS)-regs.st: printcpu
	./printcpu >$(CLASS)-regs.st

$(CLASS)-cr.st: printcpucr
	./printcpucr >$(CLASS)-cr.st

$(CLASS)-xmm.st: printcpuxmm
	./printcpuxmm >$(CLASS)-xmm.st

clean:
	rm -f $(CLASS)-regs.st $(CLASS)-cr.st $(CLASS)-xmm.st
	rm -f printcpu printcpucr printcpuxmm
	rm -f printcpu.exe printcpucr.exe printcpuxmm.exe

printcpu: $(BOCHSEXP)/printcpu.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpucr: $(BOCHSEXP)/printcpucr.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)

printcpuxmm: $(BOCHSEXP)/printcpuxmm.c $(LIBDEPS)
	g++ -o $@ $< $(CFLAGS)
