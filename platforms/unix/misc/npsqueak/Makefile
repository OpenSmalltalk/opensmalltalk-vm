# Netscape Plugin for Squeak on Unix platforms
# Author: Bert Freudenberg <bert@isg.cs.uni-magdeburg.de>
# Note:   See README.npsqueak for installation instructions

############ Customize flags here #######################

INC	= -I./include
CC	= gcc
CFLAGS	= -O2 $(INC) -Wall
LD	= gcc
LDFLAGS = -shared

############ compile and link ###########################

npsqueak.so : npsqueak.o npunix.o 
	$(LD) $(LDFLAGS) npsqueak.o npunix.o -o npsqueak.so 

.SUFFIXES: .c .o

.c.o:
	$(CC) $(CFLAGS) -c $<

clean:
	@rm -f *.o *~ .*~ */*~ */.*~

############ INSTALL (Experimental ...) #################

# for Mozilla, you have to copy npsqueak.so into
# Mozilla's plugins directory (/usr/lib/mozilla/plugins/)!

NETSCAPE=$(HOME)/.netscape
PLUGINS=$(NETSCAPE)/plugins
SQUEAK=$(HOME)/.npsqueak
VM=$(SQUEAK)/squeakvm
IMAGE=$(SQUEAK)/image
SECURE=$(IMAGE)/secure
UNTRUSTED=$(IMAGE)/untrusted

### directories ###

# plugin

$(NETSCAPE):
	[ -d $(NETSCAPE) ] && touch $(NETSCAPE) || mkdir $(NETSCAPE)

$(PLUGINS): $(NETSCAPE)
	[ -d $(PLUGINS) ]  && touch $(PLUGINS) || mkdir $(PLUGINS)

# vm stub, image

$(SQUEAK):
	[ -d $(SQUEAK) ] && touch $(SQUEAK) || mkdir $(SQUEAK)

$(VM): $(SQUEAK) squeakvm 
	cp squeakvm $(VM)
	chmod +x $(VM)

$(IMAGE): $(SQUEAK)
	[ -d $(IMAGE) ]  && touch $(IMAGE) || mkdir $(IMAGE)

$(UNTRUSTED): $(IMAGE)
	[ -d $(UNTRUSTED) ] && touch $(UNTRUSTED) || mkdir $(UNTRUSTED)

$(SECURE): $(IMAGE)
	[ -d $(SECURE) ] && touch $(SECURE) || mkdir $(SECURE)
	chmod go-rwx $(SECURE)

### files ###

$(PLUGINS)/npsqueak.so: $(PLUGINS) npsqueak.so
	cp npsqueak.so $(PLUGINS)/

$(SECURE)/DIRINFO: $(SECURE)
	echo 'This directory contains security keys.' > $(SECURE)/DIRINFO
	echo 'It should be accessable to the user only!' >> $(SECURE)/DIRINFO

$(UNTRUSTED)/DIRINFO: $(UNTRUSTED)
	echo 'This is the working directory for insecure content.' > $(UNTRUSTED)/DIRINFO

### Go! ###

install: $(PLUGINS)/npsqueak.so $(VM) $(SECURE)/DIRINFO $(UNTRUSTED)/DIRINFO

