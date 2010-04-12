# Last edited: 2010-04-12 07:43:29 by piumarta on ubuntu

all : .force
	[ -d bld ] || mkdir bld
	[ -f bld/Makefile ] || ( cd bld; ../cmake/configure; )
	( cd bld; $(MAKE) $(MFLAGS); )

install : all
	( cd bld; $(MAKE) $(MFLAGS) install; )

clean : .force
	/bin/rm -rf bld

.force :
