#    Makefile template for Configure for simulator common directory
#    Copyright (C) 1996-2013 Free Software Foundation, Inc.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

default: all


srcdir = .
abs_srcdir = /mnt/hgfs/tim/Documents/Squeak/Rasbian-VM/Pi-CogVM/Cog/processors/ARM/gdb-7.6/sim/common
srcroot = $(abs_srcdir)/../..

prefix = /usr/local
exec_prefix = ${prefix}

host_alias = 
target_alias = arm-linux
program_transform_name = s&^&arm-linux-&
bindir = ${exec_prefix}/bin

libdir = ${exec_prefix}/lib
tooldir = $(libdir)/$(target_alias)

datarootdir = ${prefix}/share
datadir = ${datarootdir}
mandir = ${datarootdir}/man
man1dir = $(mandir)/man1
infodir = ${datarootdir}/info
includedir = ${prefix}/include

SHELL = /bin/sh

INSTALL = /usr/bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644

CC = gcc
CC_FOR_BUILD = $(CC)
CFLAGS = -g -O2
SIM_CFLAGS = 

# These are used to rebuild nltvals.def.
CPP_FOR_TARGET = `   if test -f $${rootme}/../../gcc/Makefile ; then     if test -f $${rootme}/../../$(TARGET_SUBDIR)/newlib/Makefile ; then       echo $${rootme}/../../gcc/xgcc -B$${rootme}/../../gcc/ -idirafter $${rootme}/../../$(TARGET_SUBDIR)/newlib/targ-include -idirafter $(srcroot)/newlib/libc/include -nostdinc;     else       echo $${rootme}/../../gcc/xgcc -B$${rootme}/../../gcc/;     fi;   else     if test '$(host_canonical)' = '$(target_canonical)' ; then       echo $(CC);     else       t='$(program_transform_name)'; echo gcc | sed -e 's/x/x/' $$t;     fi;   fi` -E
TARGET_SUBDIR = arm-linux

HDEFINES = 
TDEFINES =

CONFIG_CFLAGS = -DHAVE_CONFIG_H $(SIM_CFLAGS) $(HDEFINES) $(TDEFINES)
CSEARCH = -I. -I$(srcdir) -I$(srcroot)/include
ALL_CFLAGS = $(CFLAGS) $(CONFIG_CFLAGS) $(CSEARCH)
BUILD_CFLAGS = -g -O $(CSEARCH)

AR = ar
AR_FLAGS = rc
RANLIB = ranlib
MAKEINFO = makeinfo

.NOEXPORT:
MAKEOVERRIDES=

all:

# Generate nltvals.def for newlib/libgloss using devo and build tree.
# This file is shipped with distributions so we build in the source dir.
# Use `make headers' to rebuild.
# Note: If gdb releases begin to contain target header files (not a good idea,
# but if they did ...), targ-vals.def coud be generated at build time.
# An alternative is to slurp in the tables at runtime.
.PHONY: headers
headers:
	rootme=`pwd` ; \
	cd $(srcdir) ; \
	rm -f nltvals.new ; \
	$(SHELL) $(abs_srcdir)/gennltvals.sh $(SHELL) $(srcroot) "$(CPP_FOR_TARGET)" > nltvals.new ; \
	$(SHELL) $(srcroot)/move-if-change nltvals.new nltvals.def

.c.o:
	$(CC) -c $< $(ALL_CFLAGS)

check:

info:
clean-info:
install-info:

tags etags: TAGS

# Macros like EXTERN_SIM_CORE confuse tags.
# And the sim-n-foo.h files create functions that can't be found either.
TAGS: force
	cd $(srcdir) && \
	etags --regex '/^\([a-z_]+\) (/\1/' --regex '/^.*\/[*] TAGS: .*/' \
		*.c *.h

clean:
	rm -f *.[oa] *~ core

distclean mostlyclean maintainer-clean realclean: clean
	rm -f TAGS
	rm -f Makefile config.cache config.log config.status
	rm -f cconfig.h config.h stamp-h

# Dummy target to force execution of dependent targets.
force:

# Copy the files into directories where they will be run.
install: install-man

install-man: installdirs
	n=`echo run | sed '$(program_transform_name)'`; \
	$(INSTALL_DATA) $(srcdir)/run.1 $(DESTDIR)$(man1dir)/$$n.1

installdirs:
	$(SHELL) $(srcdir)/../../mkinstalldirs $(DESTDIR)$(man1dir)

Makefile: Makefile.in config.status
	$(SHELL) ./config.status

config.status: configure
	$(SHELL) ./config.status --recheck

config.h: stamp-h ; @true
stamp-h: config.in config.status
	CONFIG_FILES= CONFIG_HEADERS=config.h:config.in $(SHELL) ./config.status
