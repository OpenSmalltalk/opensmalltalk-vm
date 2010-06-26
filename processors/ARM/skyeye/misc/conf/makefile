MAJOR_VERSION = 1
MINOR_VERSION = 3
MICRO_VERSION = 0
EXTRAVERSION =

MINIGUI_RELEASE=$(MAJOR_VERSION).$(MINOR_VERSION).$(MICRO_VERSION)$(EXTRAVERSION)

# SUBARCH tells the usermode build what the underlying arch is.  That is set
# first, and if a usermode build is happening, the "ARCH=um" on the command
# line overrides the setting of ARCH below.  If a native build is happening,
# then ARCH is assigned, getting whatever value it gets normally, and 
# SUBARCH is subsequently ignored.

SUBARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/)
ARCH := $(SUBARCH)

MINIGUI_PATH=kernel-$(shell echo $(MINIGUI_RELEASE) | sed -e "s/-//g")

CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	  else if [ -x /bin/bash ]; then echo /bin/bash; \
	  else echo sh; fi ; fi)
TOPDIR	:= $(shell /bin/pwd)

HPATH   	= $(TOPDIR)/include

HOSTCC  	= gcc
HOSTCFLAGS	= -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer

CROSS_COMPILE 	=

#
# Include the make variables (CC, etc...)
#

AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
CC		= $(CROSS_COMPILE)gcc
CPP		= $(CC) -E
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
STRIP		= $(CROSS_COMPILE)strip
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump
MAKEFILES	= $(TOPDIR)/.config
GENKSYMS	= /sbin/genksyms
DEPMOD		= /sbin/depmod
KALLSYMS	= /sbin/kallsyms
MODFLAGS	= -DMODULE
CFLAGS_KERNEL	=
PERL		= perl
AWK		= awk
TMPPREFIX	=

export	MAJOR_VERSION MINOR_VERSION MICRO_VERSION EXTRAVERSION MINIGUI_RELEASE ARCH \
	CONFIG_SHELL TOPDIR HPATH HOSTCC HOSTCFLAGS CROSS_COMPILE AS LD CC \
	CPP AR NM STRIP OBJCOPY OBJDUMP MAKE MAKEFILES GENKSYMS MODFLAGS PERL AWK

-include Makefile

doit:
	@echo "You may need to run configure script to build Makefile."

.PHONY : menuconfig
menuconfig:
	$(MAKE) -C scripts/lxdialog -f makefile.lx all
	$(CONFIG_SHELL) scripts/Menuconfig configs/config.in

.PHONY : defconfig
defconfig:
	@cp configs/defconfig .defconfig
	$(MAKE) -C scripts/lxdialog -f makefile.lx all
	$(CONFIG_SHELL) scripts/Menuconfig configs/config.in
	@rm .defconfig
