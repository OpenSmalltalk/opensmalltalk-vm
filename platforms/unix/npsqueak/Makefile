# Netscape Plugin for Squeak on Unix platforms
# Author: Bert Freudenberg
# Last edited: 2007-10-12 20:03:33 by piumarta on emilia

############ Customize flags here #######################

INC	= -I./include -I/usr/X11R6/include
CC	= gcc
CFLAGS	= $(INC) -O2 -fPIC -Wall
LD	= gcc
LDFLAGS = -lXt

# usually overridden from top level makefile
VM_VERSION=  3.9-12
bindir=	     /usr/local/bin
imgdir=	     /usr/local/share/squeak
plgdir=	     /usr/local/lib/squeak/$(VM_VERSION)

# configuration
scriptdir=	$(imgdir)
npsqueakrun=	npsqueakrun


############ compile and link ###########################
all: npsqueak.so npsqueakrun

npsqueak.so : npsqueak.la 
	-@rm -f $@ 
	ln .libs/npsqueak $@ 

npsqueak.la : npsqueak.lo npunix.lo 
	../libtool --mode=link $(LD) $(LDFLAGS) npsqueak.lo npunix.lo -avoid-version -module -rpath $(plgdir) -o $@

npsqueak.lo: npsqueak.c ../config.h
	../libtool --mode=compile $(CC) -c $(CFLAGS) \
		-DSYSTEM_BIN_DIR=\"$(scriptdir)\" \
		-DSYSTEM_IMG_DIR=\"$(imgdir)\" \
		-DNPSQUEAKRUN=\"$(npsqueakrun)\" $<

npunix.lo: npunix.c
	../libtool --mode=compile $(CC) -c $(CFLAGS) $<

npsqueakrun: npsqueakrun.in 
	sed "s|@imgdir@|$(imgdir)|; \
	     s|@VM_VERSION@|$(VM_VERSION)|" \
		npsqueakrun.in > $@
	chmod +x $@

npsqueakregister: npsqueakregister.in 
	sed "s|@NPSQUEAK_SO@|$(plgdir)/npsqueak.so|" \
		npsqueakregister.in > $@
	chmod +x $@


clean:
	-rm -rf *.lo *.la *.o *.so *~ .*~ */*~ */.*~ .libs


############ install ####################################

$(ROOT)$(scriptdir):
	install -d $@

$(ROOT)$(plgdir): 
	install -d $@

$(ROOT)$(plgdir)/npsqueak.so: npsqueak.so $(ROOT)$(plgdir)
	cp npsqueak.so $@
	strip $@

$(ROOT)$(scriptdir)/npsqueakrun: npsqueakrun $(ROOT)$(scriptdir)
	cp npsqueakrun $@


$(ROOT)$(imgdir)/npsqueakregister: npsqueakregister $(ROOT)$(scriptdir)
	cp npsqueakregister $@

### Go! ###

NPSQUEAK_TARGETS=                   \
	$(ROOT)$(plgdir)/npsqueak.so    \
	$(ROOT)$(scriptdir)/npsqueakrun    \
	$(ROOT)$(scriptdir)/npsqueakregister

install: $(NPSQUEAK_TARGETS)

uninstall: 
	rmdir --ignore-fail-on-non-empty $(ROOT)$(imgdir)
	rm -rf $(NPSQUEAK_TARGETS)



