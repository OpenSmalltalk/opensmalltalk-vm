# Netscape Plugin for Squeak on Unix platforms
# Author: Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>

############ Customize flags here #######################

INC	= -I./include -I/usr/X11R6/include
CC	= gcc
CFLAGS	= $(INC) -O2 -fPIC -Wall
LD	= gcc
LDFLAGS = -shared

# usually overridden from top level makefile
imgdir=      /usr/local/lib/squeak
SQ_DIR=      /usr/local/lib/squeak
VM_VERSION=  3.7b-2

libdir=	   $(imgdir)/$(VM_VERSION)
VM_LIBDIR= $(SQ_DIR)/$(VM_VERSION)

############ compile and link ###########################

npsqueak.so : npsqueak.o npunix.o 
	$(LD) $(LDFLAGS) npsqueak.o npunix.o -o npsqueak.so 

npsqueak.o: npsqueak.c ../config.h
	$(CC) -c $(CFLAGS) -DVM_LIBDIR=\"$(VM_LIBDIR)\" $<

npunix.o: npunix.c
	$(CC) -c $(CFLAGS) $<

clean:
	-rm -f *.o *.so *~ .*~ */*~ */.*~

############ install ####################################

$(SQ_DIR):
	@if [ -d $@ ] ; then \
		touch $@ ; \
	else \
		echo "Error: $@ not found" ; \
		echo "You have to install squeak first!" ; \
		false ; \
	fi

$(VM_LIBDIR): $(SQ_DIR)
	@if [ -d $@ ] ; then \
		touch $@ ; \
	else \
		echo "Error: $@ not found" ; \
		echo "Is there a version mismatch? Install squeak first!" ; \
		false ; \
	fi

$(VM_LIBDIR)/npsqueak.so: npsqueak.so $(VM_LIBDIR)
	cp npsqueak.so $@
	strip $@

$(VM_LIBDIR)/npsqueakrun: npsqueakrun.in $(SQ_DIR)
	sed "s|@SQ_DIR@|$(imgdir)|;s|@VM_VERSION@|$(VM_VERSION)|" \
		npsqueakrun.in > $@
	chmod +x $@

$(SQ_DIR)/npsqueakregister: npsqueakregister.in $(SQ_DIR)
	sed "s|@NPSQUEAK_SO@|$(libdir)/npsqueak.so|" \
		npsqueakregister.in > $@
	chmod +x $@

### Go! ###

NPSQUEAK_TARGETS=                   \
	$(VM_LIBDIR)/npsqueak.so    \
	$(VM_LIBDIR)/npsqueakrun    \
	$(SQ_DIR)/npsqueakregister

install: $(NPSQUEAK_TARGETS)

#	$(SQ_DIR)/npsqueakregister

uninstall: $(SQ_DIR)/npsqueakregister
	$(SQ_DIR)/npsqueakregister -u
	rm -rf $(NPSQUEAK_TARGETS)
