CFLAGS=-m32 -I.. -I../../bochs -I../../bochs/cpu -I../../bochs/instrument/stubs -L../cpu -lcpu

all: printcpu printcpucr printcpuxmm
	./printcpu >BochsIA32Alien-regs.st
	./printcpucr >BochsIA32Alien-cr.st
	./printcpuxmm >BochsIA32Alien-xmm.st

clean:
	rm -f BochsIA32Alien-regs.st BochsIA32Alien-cr.st BochsIA32Alien-xmm.st
	rm -f printcpu printcpucr printcpuxmm
	rm -f printcpu.exe printcpucr.exe printcpuxmm.exe

printcpu: printcpu.c
	g++ -o $@ printcpu.c $(CFLAGS)

printcpucr: printcpucr.c
	g++ -o $@ printcpucr.c $(CFLAGS)

printcpuxmm: printcpuxmm.c
	g++ -o $@ printcpuxmm.c $(CFLAGS)
