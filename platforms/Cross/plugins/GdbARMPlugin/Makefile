# edit this to suit your system; it really ought to use relative paths
# or some other convenience
GDBBUILDFOLDER = /home/tim/Documents/Raspbian-Cog/gdb-arm/gdb-7.10

CC      = gcc
CFLAGS  = -I$(GBDBUILDFOLDER)/bfd 
LDFLAGS = $(GDBBUILDFOLDER)/sim/arm/libsim.a $(GDBBUILDFOLDER)/opcodes/libopcodes.a -lbfd -lintl -liberty -Wl,-wrap,ARMul_OSHandleSWI -L$(GDBBUILDFOLDER)/bfd/ 
SHAREDLIBRARYFLAGS = 

all:
# another test on linux:
#	$(CC) $(CFLAGS) armulmem.c -c -I$(GDBBUILDFOLDER)/sim/arm/ -I$(GDBBUILDFOLDER)/include/
#	$(CC) $(CFLAGS) sqGdbARMPlugin.c -c -fPIC -I$(GDBBUILDFOLDER)/sim/arm/ -I$(GDBBUILDFOLDER)/include/ -I$(GDBBUILDFOLDER)/bfd/ 
#	$(CC) -shared $(SHAREDLIBRARYFLAGS) -o GdbARMPlugin.dll sqGdbARMPlugin.o armulmem.o $(LDFLAGS)

	mkdir -p ../cog/platforms/Cross/plugins/GdbARMPlugin
	mkdir -p ../cog/platforms/win32/plugins/GdbARMPlugin
	mkdir -p ../cog/platforms/unix/plugins/GdbARMPlugin

	cp sqGdbARMPlugin.c GdbARMPlugin.h armulmem.c ../cog/platforms/Cross/plugins/GdbARMPlugin/
	cp Makefile.win32 ../cog/platforms/win32/plugins/GdbARMPlugin/Makefile
	cp Makefile.unix ../cog/platforms/unix/plugins/GdbARMPlugin/Makefile.inc
#unix
#	cd ../cog/unixbuild/bld; make install #prefix=
#windows
	cd ../cog/cygwinbuild/;make
