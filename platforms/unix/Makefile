# Last edited: 2005-03-16 22:47:32 by piumarta on squeak.hpl.hp.com

all : .force
	[ -d bld ] || mkdir bld
	[ -f bld/Makefile ] || ( cd bld; ../config/configure; )
	( cd bld; $(MAKE) $(MFLAGS); )

install : all
	( cd bld; $(MAKE) $(MFLAGS) install; )

clean : .force
	/bin/rm -rf bld

.force :
