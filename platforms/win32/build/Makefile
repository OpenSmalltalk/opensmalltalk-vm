#############################################################################
# Makefile for Win32 Squeak using gcc-2.95.2 and MingW32
#############################################################################

#############################################################################
# Base definitions:

# Where is the platform directory?
PLATDIR =../..

# What is the name of the VM to build?
VM = Squeak
VMVERSIONINFO= "3.10.6 (release)"

# Is this a Croquet VM (defaults to OGL instead of D3D)?
# CROQUET=-DCROQUET

#############################################################################
# Default locations
#
ifndef BASEDIR
BASEDIR= .
endif

SRCDIR= $(BASEDIR)/src
BLDDIR= $(BASEDIR)/obj
OBJDIR= $(BLDDIR)/vm

CROSSDIR=$(PLATDIR)/Cross/vm
WIN32DIR=$(PLATDIR)/win32/vm
MAKERDIR=$(SRCDIR)/vm
XMISCDIR=$(PLATDIR)/win32/misc

CROSSSRC= $(wildcard $(CROSSDIR)/*.c)
WIN32SRC= $(wildcard $(WIN32DIR)/*.c)
MAKERSRC= $(wildcard $(MAKERDIR)/*.c)
VMSRC   = $(notdir $(MAKERSRC) $(WIN32SRC) $(CROSSSRC))

VPATH= $(VMDIR) $(WIN32DIR) $(CROSSDIR) $(XMISCDIR)

#############################################################################
# The internal (.lib) and external (.dll) plugins
#
include $(SRCDIR)/plugins.ext
include $(SRCDIR)/plugins.int

LIBS = $(addsuffix .lib, $(INTERNAL_PLUGINS))
DLLS = $(addsuffix .dll, $(EXTERNAL_PLUGINS))

#############################################################################
# Generic VM source file definitions
#
VMDIR= $(SRCDIR)/vm
VMOBJ:=	$(VMSRC:.c=.o)
VMOBJ:=	$(filter-out interp.o sqFilePrims.o, $(VMOBJ))

#LIBSRC = $(wildcard *.c)
#LIBOBJ = $(LIBSRC:.c=.o)

#############################################################################
# SqueakVM definitions
#
VMEXE=  $(VM).exe
VMDEF=	$(VM).def
VMEXP=	$(VM).exp
VMLIB=	$(VM).lib
VMRES=	$(VM).res
VMDEFIN=$(VM).def.in


.PRECIOUS: gnu-interp.c 

#############################################################################
# DirectX definitions
#
DXDIR= c:/dx7sdk/include

#############################################################################
# C compiler settings (gcc-2.95)
#
CC=	gcc
OFLAGS= -O2
CFLAGS=	-g -mpentium -mwindows \
	-fomit-frame-pointer -funroll-loops -fschedule-insns2 $(OFLAGS)
DEFS=	-DWIN32_FILE_SUPPORT -DNO_SERVICE -DNO_STD_FILE_SUPPORT -DNDEBUG \
	-DLSB_FIRST -DVM_NAME=\"$(VM)\" -DVM_VERSIONINFO=\"$(VMVERSIONINFO)\" -DX86 $(XDEFS) $(CROQUET)
XDEFS=	-DSQUEAK_BUILTIN_PLUGIN
INCLUDES= -I. -I$(VMDIR) -I$(WIN32DIR) -I$(CROSSDIR) -I$(DXDIR) $(XINC)
MD=	mkdir

#############################################################################
# Linker settings
#
# Note: I had to use 'gcc' instead of 'ld' to prevent unresolved symbols
#       The switch '-mwindows' gives us a GUI app instead of a console app.
#
LD=	 gcc
LDFLAGS= -mwindows
STDLIBS= -lddraw -ldinput -lopengl32 -lwsock32 -lcomdlg32 -lole32 -lwinmm \
	 -lversion -luser32 -lgdi32 -lkernel32 -lcrtdll
#LIBS=	 $(STDLIBS) $(CRTLIB)

#############################################################################
# Gnuifier settings
#
AWK=		gawk
GNUIFY= $(PLATDIR)/win32/misc/gnuify

#############################################################################
# Tools to use
#
AR = ar rc
CP = cp
RM = rm
DLLTOOL=	dlltool
DLLWRAP=	dllwrap

#############################################################################
# RC settings
#
# Note: RC compiles the .rc files into linkable .o files
#
RC=	 windres
RCFLAGS= 

.SUFFIXES:
.SUFFIXES:	.ccg .cc .c .o .s .i .rc .res .cg .hg .ccg



#############################################################################
# Common build rules
#
default: print-settings $(OBJDIR) $(VMEXE) $(DLLS)

print-settings:
	@echo ---------------- Makefile settings ------------------
	@echo VPATH=$(VPATH)
	@echo INCLUDES=$(INCLUDES)
	@echo CFLAGS=$(CFLAGS)
	@echo -----------------------------------------------------

$(VMEXE): gnu-interp.c $(VMOBJ) $(LIBS) $(VMEXP) resource.o
	$(LD) $(LDFLAGS) -o $(OBJDIR)/$(VMEXE) $(addprefix $(OBJDIR)/,$(VMOBJ)) $(OBJDIR)/$(VMEXP) $(OBJDIR)/resource.o $(addprefix $(OBJDIR)/,$(LIBS)) $(STDLIBS)
	$(RM) $(OBJDIR)/version.o
	strip --strip-all $(OBJDIR)/$(VMEXE)

$(OBJDIR):
	mkdir $(subst /,\,$(OBJDIR))

#############################################################################
# The exports for named primitives from Squeak (required by VM)
#
$(VMDEF) $(VMEXP) $(VMLIB): $(VMOBJ)
	$(DLLTOOL) --input-def $(VMDEFIN) --output-def $(OBJDIR)/$(VMDEF) --output-exp $(OBJDIR)/$(VMEXP) --output-lib $(OBJDIR)/$(VMLIB) $(addprefix $(OBJDIR)/,$(VMOBJ))

#############################################################################
# Building plugins

%.lib: $(BLDDIR)/%/Makefile.lib
	$(MAKE) -C $(BLDDIR)/$* -fMakefile.lib LIBNAME=$* \
	PLATDIR=../../$(PLATDIR) BASEDIR=../../$(BASEDIR) \
	XDEFS=-DSQUEAK_BUILTIN_PLUGIN $*.lib
	@$(CP) $(BLDDIR)/$*/$*.lib $(OBJDIR)

# Check for Makefile in win32 plugins directory
$(BLDDIR)/%/Makefile.lib: $(PLATDIR)/win32/plugins/%/Makefile
	-mkdir $(subst /,\,$(BLDDIR)/$*)
	cp $< $@

# Otherwise use default Makefile
$(BLDDIR)/%/Makefile.lib: Makefile.plugin
	-mkdir $(subst /,\,$(BLDDIR)/$*)
	cp $< $@

%.dll: $(BLDDIR)/%/Makefile.dll
	$(MAKE) -C $(BLDDIR)/$* -fMakefile.dll LIBNAME=$* \
		PLATDIR=../../$(PLATDIR) BASEDIR=../../$(BASEDIR) \
		$*.dll
	@$(CP) $(BLDDIR)/$*/$*.dll $(OBJDIR)

# Check for Makefile in win32 plugins directory
$(BLDDIR)/%/Makefile.dll: $(PLATDIR)/win32/plugins/%/Makefile
	@-mkdir $(subst /,\,$(BLDDIR)/$*)
	@cp $< $@

# Otherwise use default Makefile
$(BLDDIR)/%/Makefile.dll: Makefile.plugin
	@-mkdir $(subst /,\,$(BLDDIR)/$*)
	@cp $< $@


#############################################################################
# Basic rules

.c.o:
		$(CC) -o $(OBJDIR)/$@ $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

.c.s:
		$(CC) -S -o $@ -fverbose-asm -Wa,ah $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

gnu-interp.c:	interp.c $(GNUIFY)
		$(AWK) -f $(GNUIFY) $< > $(VMDIR)/$@

.rc.res:
		$(RC) $(RCFLAGS) --include-dir $(dir $<) -i $< -o $(OBJDIR)/$@

resource.o:	$(VMRES)
		$(RC) $(RCFLAGS) -i $(OBJDIR)/$< -o $(OBJDIR)/$@

#############################################################################
# Extra specific dependencies
#

sqNamedPrims.o:	sqNamedPrims.c sqNamedPrims.h

#Squeak.res: misc/Squeak.rc
#	$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@
#
#Croquet.res: misc/Croquet.rc
#	$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@

