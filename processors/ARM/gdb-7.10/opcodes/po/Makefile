# Makefile for program source directory in GNU NLS utilities package.
# Copyright (C) 1995, 1996, 1997 by Ulrich Drepper <drepper@gnu.ai.mit.edu>
# Copyright (C) 2003-2015 Free Software Foundation, Inc.
#
# This file may be copied and used freely without restrictions.  It can
# be used in projects which are not available under the GNU Public License
# but which still want to provide support for the GNU gettext functionality.
# Please note that the actual code is *not* freely available.

PACKAGE = opcodes
VERSION = 2.25.51

SHELL = /bin/sh


srcdir = .
top_srcdir = ..

top_builddir = ..

prefix = /usr/local
exec_prefix = ${prefix}
datadir = $(prefix)/
localedir = $(datadir)/locale
gnulocaledir = $(prefix)/share/locale
gettextsrcdir = $(prefix)/share/gettext/po
subdir = po

DESTDIR =

INSTALL = /usr/bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
MKINSTALLDIRS = $(top_builddir)/./../mkinstalldirs

CC = gcc
GENCAT = 
GMSGFMT = PATH=../src:$$PATH /usr/bin/msgfmt
MSGFMT = /usr/bin/msgfmt
XGETTEXT = PATH=../src:$$PATH /usr/bin/xgettext
MSGMERGE = PATH=../src:$$PATH msgmerge

DEFS = -DHAVE_CONFIG_H
CFLAGS = -g -O2
CPPFLAGS = 

INCLUDES = -I.. -I$(top_srcdir)/intl

COMPILE = $(CC) -c $(DEFS) $(INCLUDES) $(CPPFLAGS) $(CFLAGS) $(XCFLAGS)

SOURCES = cat-id-tbl.c
POFILES =  fr.po sv.po tr.po es.po da.po de.po id.po pt_BR.po ro.po nl.po fi.po vi.po ga.po zh_CN.po it.po uk.po
GMOFILES =  fr.gmo sv.gmo tr.gmo es.gmo da.gmo de.gmo id.gmo pt_BR.gmo ro.gmo nl.gmo fi.gmo vi.gmo ga.gmo zh_CN.gmo it.gmo uk.gmo
DISTFILES = ChangeLog Makefile.in.in POTFILES.in $(PACKAGE).pot \
stamp-cat-id $(POFILES) $(GMOFILES) $(SOURCES)

POTFILES = \
     ../aarch64-asm-2.c \
     ../aarch64-asm.c \
     ../aarch64-asm.h \
     ../aarch64-dis-2.c \
     ../aarch64-dis.c \
     ../aarch64-dis.h \
     ../aarch64-gen.c \
     ../aarch64-opc-2.c \
     ../aarch64-opc.c \
     ../aarch64-opc.h \
     ../aarch64-tbl.h \
     ../alpha-dis.c \
     ../alpha-opc.c \
     ../arc-dis.c \
     ../arc-ext.c \
     ../arc-opc.c \
     ../arm-dis.c \
     ../avr-dis.c \
     ../bfin-dis.c \
     ../cgen-asm.c \
     ../cgen-bitset.c \
     ../cgen-dis.c \
     ../cgen-opc.c \
     ../cr16-dis.c \
     ../cr16-opc.c \
     ../cris-dis.c \
     ../cris-opc.c \
     ../crx-dis.c \
     ../crx-opc.c \
     ../d10v-dis.c \
     ../d10v-opc.c \
     ../d30v-dis.c \
     ../d30v-opc.c \
     ../dis-buf.c \
     ../dis-init.c \
     ../disassemble.c \
     ../dlx-dis.c \
     ../epiphany-asm.c \
     ../epiphany-desc.c \
     ../epiphany-desc.h \
     ../epiphany-dis.c \
     ../epiphany-ibld.c \
     ../epiphany-opc.c \
     ../epiphany-opc.h \
     ../fr30-asm.c \
     ../fr30-desc.c \
     ../fr30-desc.h \
     ../fr30-dis.c \
     ../fr30-ibld.c \
     ../fr30-opc.c \
     ../fr30-opc.h \
     ../frv-asm.c \
     ../frv-desc.c \
     ../frv-desc.h \
     ../frv-dis.c \
     ../frv-ibld.c \
     ../frv-opc.c \
     ../frv-opc.h \
     ../ft32-dis.c \
     ../ft32-opc.c \
     ../h8300-dis.c \
     ../h8500-dis.c \
     ../h8500-opc.h \
     ../hppa-dis.c \
     ../i370-dis.c \
     ../i370-opc.c \
     ../i386-dis.c \
     ../i386-gen.c \
     ../i386-init.h \
     ../i386-opc.c \
     ../i386-opc.h \
     ../i386-tbl.h \
     ../i860-dis.c \
     ../i960-dis.c \
     ../ia64-asmtab.c \
     ../ia64-asmtab.h \
     ../ia64-dis.c \
     ../ia64-gen.c \
     ../ia64-opc-a.c \
     ../ia64-opc-b.c \
     ../ia64-opc-d.c \
     ../ia64-opc-f.c \
     ../ia64-opc-i.c \
     ../ia64-opc-m.c \
     ../ia64-opc.c \
     ../ia64-opc.h \
     ../ip2k-asm.c \
     ../ip2k-desc.c \
     ../ip2k-desc.h \
     ../ip2k-dis.c \
     ../ip2k-ibld.c \
     ../ip2k-opc.c \
     ../ip2k-opc.h \
     ../iq2000-asm.c \
     ../iq2000-desc.c \
     ../iq2000-desc.h \
     ../iq2000-dis.c \
     ../iq2000-ibld.c \
     ../iq2000-opc.c \
     ../iq2000-opc.h \
     ../lm32-asm.c \
     ../lm32-desc.c \
     ../lm32-desc.h \
     ../lm32-dis.c \
     ../lm32-ibld.c \
     ../lm32-opc.c \
     ../lm32-opc.h \
     ../lm32-opinst.c \
     ../m10200-dis.c \
     ../m10200-opc.c \
     ../m10300-dis.c \
     ../m10300-opc.c \
     ../m32c-asm.c \
     ../m32c-desc.c \
     ../m32c-desc.h \
     ../m32c-dis.c \
     ../m32c-ibld.c \
     ../m32c-opc.c \
     ../m32c-opc.h \
     ../m32r-asm.c \
     ../m32r-desc.c \
     ../m32r-desc.h \
     ../m32r-dis.c \
     ../m32r-ibld.c \
     ../m32r-opc.c \
     ../m32r-opc.h \
     ../m32r-opinst.c \
     ../m68hc11-dis.c \
     ../m68hc11-opc.c \
     ../m68k-dis.c \
     ../m68k-opc.c \
     ../m88k-dis.c \
     ../mcore-dis.c \
     ../mcore-opc.h \
     ../mep-asm.c \
     ../mep-desc.c \
     ../mep-desc.h \
     ../mep-dis.c \
     ../mep-ibld.c \
     ../mep-opc.c \
     ../mep-opc.h \
     ../metag-dis.c \
     ../microblaze-dis.c \
     ../microblaze-opc.h \
     ../micromips-opc.c \
     ../mips-dis.c \
     ../mips-opc.c \
     ../mips16-opc.c \
     ../mmix-dis.c \
     ../mmix-opc.c \
     ../moxie-dis.c \
     ../moxie-opc.c \
     ../msp430-decode.c \
     ../msp430-dis.c \
     ../mt-asm.c \
     ../mt-desc.c \
     ../mt-desc.h \
     ../mt-dis.c \
     ../mt-ibld.c \
     ../mt-opc.c \
     ../mt-opc.h \
     ../nds32-asm.c \
     ../nds32-dis.c \
     ../nios2-dis.c \
     ../nios2-opc.c \
     ../ns32k-dis.c \
     ../or1k-asm.c \
     ../or1k-desc.c \
     ../or1k-dis.c \
     ../or1k-ibld.c \
     ../or1k-opc.c \
     ../pdp11-dis.c \
     ../pdp11-opc.c \
     ../pj-dis.c \
     ../pj-opc.c \
     ../ppc-dis.c \
     ../ppc-opc.c \
     ../rl78-decode.c \
     ../rl78-dis.c \
     ../rx-decode.c \
     ../rx-dis.c \
     ../s390-dis.c \
     ../s390-mkopc.c \
     ../s390-opc.c \
     ../score-dis.c \
     ../score-opc.h \
     ../score7-dis.c \
     ../sh-dis.c \
     ../sh-opc.h \
     ../sh64-dis.c \
     ../sh64-opc.c \
     ../sh64-opc.h \
     ../sparc-dis.c \
     ../sparc-opc.c \
     ../spu-dis.c \
     ../spu-opc.c \
     ../sysdep.h \
     ../tic30-dis.c \
     ../tic4x-dis.c \
     ../tic54x-dis.c \
     ../tic54x-opc.c \
     ../tic6x-dis.c \
     ../tic80-dis.c \
     ../tic80-opc.c \
     ../tilegx-dis.c \
     ../tilegx-opc.c \
     ../tilepro-dis.c \
     ../tilepro-opc.c \
     ../v850-dis.c \
     ../v850-opc.c \
     ../vax-dis.c \
     ../visium-dis.c \
     ../visium-opc.c \
     ../w65-dis.c \
     ../w65-opc.h \
     ../xc16x-asm.c \
     ../xc16x-desc.c \
     ../xc16x-desc.h \
     ../xc16x-dis.c \
     ../xc16x-ibld.c \
     ../xc16x-opc.c \
     ../xc16x-opc.h \
     ../xgate-dis.c \
     ../xgate-opc.c \
     ../xstormy16-asm.c \
     ../xstormy16-desc.c \
     ../xstormy16-desc.h \
     ../xstormy16-dis.c \
     ../xstormy16-ibld.c \
     ../xstormy16-opc.c \
     ../xstormy16-opc.h \
     ../xtensa-dis.c \
     ../z80-dis.c \
     ../z8k-dis.c \
     ../z8k-opc.h \
     ../z8kgen.c

CATALOGS = 
CATOBJEXT = 
INSTOBJEXT = 

.SUFFIXES:
.SUFFIXES: .c .o .po .pox .gmo .mo .msg .cat

.c.o:
	$(COMPILE) $<

.po.pox:
	$(MAKE) $(PACKAGE).pot
	$(MSGMERGE) $< $(srcdir)/$(PACKAGE).pot -o $*.pox

.po.mo:
	$(MSGFMT) -o $@ $<

.po.gmo:
	file=`echo $* | sed 's,.*/,,'`.gmo \
	  && rm -f $$file && $(GMSGFMT) -o $$file $<

.po.cat:
	sed -f ../intl/po2msg.sed < $< > $*.msg \
	  && rm -f $@ && $(GENCAT) $@ $*.msg


all: all-yes

all-yes: $(CATALOGS) # $(PACKAGE).pot
all-no:

$(srcdir)/$(PACKAGE).pot: $(POTFILES)
	$(XGETTEXT) --default-domain=$(PACKAGE) --directory=$(top_srcdir) \
	  --add-comments --keyword=_ --keyword=N_ \
	  --msgid-bugs-address=bug-binutils@gnu.org \
	  --files-from=$(srcdir)/POTFILES.in
	rm -f $(srcdir)/$(PACKAGE).pot
	mv $(PACKAGE).po $(srcdir)/$(PACKAGE).pot

$(srcdir)/cat-id-tbl.c: stamp-cat-id; @:
$(srcdir)/stamp-cat-id: $(PACKAGE).pot
	rm -f cat-id-tbl.tmp
	sed -f ../intl/po2tbl.sed $(srcdir)/$(PACKAGE).pot \
		| sed -e "s/@PACKAGE NAME@/$(PACKAGE)/" > cat-id-tbl.tmp
	if cmp -s cat-id-tbl.tmp $(srcdir)/cat-id-tbl.c; then \
	  rm cat-id-tbl.tmp; \
	else \
	  echo cat-id-tbl.c changed; \
	  rm -f $(srcdir)/cat-id-tbl.c; \
	  mv cat-id-tbl.tmp $(srcdir)/cat-id-tbl.c; \
	fi
	cd $(srcdir) && rm -f stamp-cat-id && echo timestamp > stamp-cat-id


install: install-exec install-data
install-exec:
install-info:
install-html:
install-pdf:
install-data: install-data-yes
install-data-no: all
install-data-yes: all
	if test -r $(MKINSTALLDIRS); then \
	  $(MKINSTALLDIRS) $(DESTDIR)$(datadir); \
	else \
	  $(top_srcdir)/mkinstalldirs $(DESTDIR)$(datadir); \
	fi
	@catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  case "$$cat" in \
	    *.gmo) destdir=$(gnulocaledir);; \
	    *)     destdir=$(localedir);; \
	  esac; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  dir=$(DESTDIR)$$destdir/$$lang/LC_MESSAGES; \
	  if test -r $(MKINSTALLDIRS); then \
	    $(MKINSTALLDIRS) $$dir; \
	  else \
	    $(top_srcdir)/mkinstalldirs $$dir; \
	  fi; \
	  if test -r $$cat; then \
	    $(INSTALL_DATA) $$cat $$dir/$(PACKAGE)$(INSTOBJEXT); \
	    echo "installing $$cat as $$dir/$(PACKAGE)$(INSTOBJEXT)"; \
	  else \
	    $(INSTALL_DATA) $(srcdir)/$$cat $$dir/$(PACKAGE)$(INSTOBJEXT); \
	    echo "installing $(srcdir)/$$cat as" \
		 "$$dir/$(PACKAGE)$(INSTOBJEXT)"; \
	  fi; \
	  if test -r $$cat.m; then \
	    $(INSTALL_DATA) $$cat.m $$dir/$(PACKAGE)$(INSTOBJEXT).m; \
	    echo "installing $$cat.m as $$dir/$(PACKAGE)$(INSTOBJEXT).m"; \
	  else \
	    if test -r $(srcdir)/$$cat.m ; then \
	      $(INSTALL_DATA) $(srcdir)/$$cat.m \
		$$dir/$(PACKAGE)$(INSTOBJEXT).m; \
	      echo "installing $(srcdir)/$$cat as" \
		   "$$dir/$(PACKAGE)$(INSTOBJEXT).m"; \
	    else \
	      true; \
	    fi; \
	  fi; \
	done
	if test "$(PACKAGE)" = "gettext"; then \
	  if test -r $(MKINSTALLDIRS); then \
	    $(MKINSTALLDIRS) $(DESTDIR)$(gettextsrcdir); \
	  else \
	    $(top_srcdir)/mkinstalldirs $(DESTDIR)$(gettextsrcdir); \
	  fi; \
	  $(INSTALL_DATA) $(srcdir)/Makefile.in.in \
			  $(DESTDIR)$(gettextsrcdir)/Makefile.in.in; \
	else \
	  : ; \
	fi

# Define this as empty until I found a useful application.
installcheck:

uninstall:
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  rm -f $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT); \
	  rm -f $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT).m; \
	  rm -f $(DESTDIR)$(gnulocaledir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT); \
	  rm -f $(DESTDIR)$(gnulocaledir)/$$lang/LC_MESSAGES/$(PACKAGE)$(INSTOBJEXT).m; \
	done
	rm -f $(DESTDIR)$(gettextsrcdir)/po-Makefile.in.in

check: all

cat-id-tbl.o: ../intl/libgettext.h

html dvi pdf ps info tags TAGS ID:

mostlyclean:
	rm -f core core.* *.pox $(PACKAGE).po *.old.po cat-id-tbl.tmp
	rm -fr *.o

clean: mostlyclean

distclean: clean
	rm -f Makefile Makefile.in POTFILES *.mo *.msg *.cat *.cat.m

maintainer-clean: distclean
	@echo "This command is intended for maintainers to use;"
	@echo "it deletes files that may require special tools to rebuild."
	rm -f $(GMOFILES)

distdir = ../$(PACKAGE)-$(VERSION)/$(subdir)
dist distdir: update-po $(DISTFILES)
	dists="$(DISTFILES)"; \
	for file in $$dists; do \
	  ln $(srcdir)/$$file $(distdir) 2> /dev/null \
	    || cp -p $(srcdir)/$$file $(distdir); \
	done

update-po: Makefile
	$(MAKE) $(PACKAGE).pot
	PATH=`pwd`/../src:$$PATH; \
	cd $(srcdir); \
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
	  mv $$lang.po $$lang.old.po; \
	  echo "$$lang:"; \
	  if $(MSGMERGE) $$lang.old.po $(PACKAGE).pot -o $$lang.po; then \
	    rm -f $$lang.old.po; \
	  else \
	    echo "msgmerge for $$cat failed!"; \
	    rm -f $$lang.po; \
	    mv $$lang.old.po $$lang.po; \
	  fi; \
	done

POTFILES: POTFILES.in
	( if test 'x$(srcdir)' != 'x.'; then \
	    posrcprefix='$(top_srcdir)/'; \
	  else \
	    posrcprefix="../"; \
	  fi; \
	  rm -f $@-t $@ \
	    && (sed -e '/^#/d' -e '/^[ 	]*$$/d' \
		    -e "s@.*@	$$posrcprefix& \\\\@" < $(srcdir)/$@.in \
		| sed -e '$$s/\\$$//') > $@-t \
	    && chmod a-w $@-t \
	    && mv $@-t $@ )

POTFILES.in: # ../Makefile
	cd .. && $(MAKE) po/POTFILES.in

Makefile: Make-in ../config.status POTFILES
	cd .. \
	  && CONFIG_FILES=$(subdir)/Makefile.in:$(subdir)/Make-in \
	     CONFIG_HEADERS= $(SHELL) ./config.status

# Tell versions [3.59,3.63) of GNU make not to export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
