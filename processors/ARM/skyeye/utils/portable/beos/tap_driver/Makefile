ifneq ($(OSTYPE),beos)
### for cross-compile
CC = /usr/local/bin/i586-beos-gcc
KERNEL = /usr/local/i586-beos/lib/_KERNEL_
else
KERNEL = /boot/develop/lib/x86/_KERNEL_
endif

EXTRA_CFLAGS ?=
CFLAGS = -O3 -no-fpic $(EXTRA_CFLAGS)

OBJECTS = skyeye_tap.o

skyeye_tap : $(OBJECTS)
	$(CC) -nostdlib $^ -o $@ $(KERNEL)

all: skyeye_tap

clean:
	-rm -f Makefile.dep
	-rm -f *.o
	-rm -f skyeye_tap

ifeq ($(OSTYPE),beos)

install: skyeye_tap
	-mkdir -p /boot/home/config/add-ons/kernel/drivers/bin
	-cp -f ./skyeye_tap /boot/home/config/add-ons/kernel/drivers/bin/skyeye_tap
	-mkdir -p /boot/home/config/add-ons/kernel/drivers/dev/net
	-ln -sf ../../bin/skyeye_tap /boot/home/config/add-ons/kernel/drivers/dev/net/skyeye_tap

uninstall:
	-rm -f /boot/home/config/add-ons/kernel/drivers/dev/net/skyeye_tap
	-rm -f /boot/home/config/add-ons/kernel/drivers/bin/skyeye_tap

else

install:
	@echo "*** You don't need this when cross-compile."

uninstall:
	@echo "*** You don't need this when cross-compile."

endif

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

Makefile.dep:
	-$(CC) $(CFLAGS) -MM skyeye_tap.c > Makefile.dep

-include Makefile.dep
