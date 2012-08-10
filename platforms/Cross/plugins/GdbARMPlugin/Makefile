CC      = gcc
CFLAGS  = 
LDFLAGS = libsim.a $(GDBBUILDFOLDER)/opcodes/libopcodes.a -lbfd -lintl -liberty -Wl,-wrap,ARMul_OSHandleSWI
GDBBUILDFOLDER = /d/build/gdb-7.4
SHAREDLIBRARYFLAGS = 

all:
	$(CC) $(CFLAGS) armulmem.c -c -I$(GDBBUILDFOLDER)/sim/arm/
	$(CC) $(CFLAGS) sqGdbARMPlugin.c -c -fPIC -I$(GDBBUILDFOLDER)/sim/arm/
	gcc -shared $(SHAREDLIBRARYFLAGS) -o GdbARMPlugin.dll sqGdbARMPlugin.o armulmem.o $(LDFLAGS)
#	mkdir ../cog/platforms/Cross/plugins/GdbARMPlugin
#	mkdir ../cog/platforms/win32/plugins/GdbARMPlugin
	cp sqGdbARMPlugin.c GdbARMPlugin.h armulmem.c ../cog/platforms/Cross/plugins/GdbARMPlugin/
	cp Makefile.win32 ../cog/platforms/win32/plugins/GdbARMPlugin/Makefile
	cd ../cog/cygwinbuild; make
