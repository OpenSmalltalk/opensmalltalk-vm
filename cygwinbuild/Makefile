#############################################################################
# Makefile for Win32 Squeak using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

#############################################################################
# Base definitions:

# The name of the VM to build
VM:=Croquet

# Is this a Croquet VM (defaults to OGL instead of D3D)?
CROQUET:=-DCROQUET

#############################################################################
# Default locations
#
ifndef BASEDIR
BASEDIR:=.
endif

SRCDIR:= ../src
BLDDIR:= $(BASEDIR)/build
OBJDIR:= $(BLDDIR)/vm

# N.B. PLATDIR *must* be a relative path, see -f../../$(shell eitheror ... below
PLATDIR:=../platforms
CROSSDIR:=$(PLATDIR)/Cross/vm
WIN32DIR:=$(PLATDIR)/win32/vm
MAKERDIR:=$(SRCDIR)/vm
WIN32MISCDIR:=$(PLATDIR)/win32/misc
WIN32UTILDIR:=$(PLATDIR)/win32/util

CROSSSRC:= $(wildcard $(CROSSDIR)/*.c) $(wildcard $(CROSSDIR)/*.cpp)
WIN32SRC:= $(wildcard $(WIN32DIR)/*.c) $(wildcard $(WIN32DIR)/*.cpp)
MAKERSRC:= $(MAKERDIR)/gcc3x-cointerp.c $(MAKERDIR)/cogit.c
VMSRC:= $(notdir $(MAKERSRC) $(WIN32SRC) $(CROSSSRC))

VPATH:= $(MAKERDIR) $(WIN32DIR) $(CROSSDIR)

#############################################################################
# The internal (.lib) and external (.dll) plugins
#
include plugins.ext
include plugins.int

LIBS:= $(addprefix $(OBJDIR)/, $(addsuffix .lib, $(INTERNAL_PLUGINS)))
DLLS:= $(addprefix $(OBJDIR)/, $(addsuffix .dll, $(EXTERNAL_PLUGINS)))

#############################################################################
# Generic VM source file definitions
#
VMDIR:= $(SRCDIR)/vm
VMOBJ:=	$(VMSRC:.c=.o)
VMOBJ:=	$(filter-out sqFilePrims.o, $(VMOBJ)) # why filter-out sqFilePrims.o?
VMOBJ:= $(addprefix $(OBJDIR)/,$(VMOBJ))

#LIBSRC:= $(wildcard *.c)
#LIBOBJ:= $(LIBSRC:.c=.o)

#############################################################################
# SqueakVM definitions
#
VMEXE:=  $(OBJDIR)/$(VM)Unstripped.exe
CONSOLEVMEXE:=  $(OBJDIR)/$(VM)ConsoleUnstripped.exe
STRIPEXE:=  $(OBJDIR)/$(VM).exe
STRIPCONSOLEEXE:=  $(OBJDIR)/$(VM)Console.exe
VMDEF:=	$(VM).def
VMEXP:=	$(OBJDIR)/$(VM).exp
VMMAP:=	$(OBJDIR)/$(VM).map
CONSOLEVMMAP:=	$(OBJDIR)/$(VM)Console.map
VMLIB:=	$(VM).lib
VMRES:=	$(VM).res
VMDEFIN:=$(BASEDIR)/$(VM).def.in
BTOBJ:= $(OBJDIR)/btext.o
ETOBJ:= $(OBJDIR)/etext.o


.PRECIOUS: eitheror.exe mkNamedPrims.exe

#############################################################################
# DirectX definitions
#
DXDIR:=     $(PLATDIR)/win32/third-party/dx9sdk/Include

#############################################################################
# C compiler settings (gcc-3.4.4 cygwin 19.24)
#
# Define NDEBUG for production so that asserts will be excluded.
NDEBUG:=-DNDEBUG
# Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)
WINVER:=-D_WIN32_WINNT=0x0501 -DWINVER=0x0501
CC:=	gcc
# define _MT to eliminate the inline versions of printf et al in mingw/stdio.h
OFLAGS:= -D_MT -O2 -march=pentium4 -momit-leaf-frame-pointer -funroll-loops \
		-fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf
INCLUDEPATH:= -isystem/usr/include/mingw -I/usr/include/w32api
CFLAGS:= $(INCLUDEPATH) -msse2 -ggdb2 -mwindows -mno-cygwin -mwin32 \
	-mno-rtd -mms-bitfields -mno-accumulate-outgoing-args $(OFLAGS)
DEFS:=	$(WINVER) -DWIN32 -DWIN32_FILE_SUPPORT -DNO_ISNAN \
		-DNO_SERVICE -DNO_STD_FILE_SUPPORT \
		$(NDEBUG) -DLSB_FIRST -DVM_NAME=\"$(VM)\" -DX86 $(XDEFS) $(CROQUET)
XDEFS:=	-DSQUEAK_BUILTIN_PLUGIN
INCLUDES:= -I. -I$(VMDIR) -I$(WIN32DIR) -I$(CROSSDIR) -I$(DXDIR) $(XINC)

#############################################################################
# Linker settings
#
# Note: I had to use 'gcc' instead of 'ld' to prevent unresolved symbols
#       The switch '-mwindows' gives us a GUI app instead of a console app.
#
LD:=	 gcc
LDFLAGS:= -mno-cygwin -mwindows -Wl,--export-dynamic -L/usr/lib/mingw
CONSOLELDFLAGS:= -mno-cygwin -mconsole -Wl,--export-dynamic -L/usr/lib/mingw
STDLIBS:= -lddraw -ldinput -lopengl32 -lwsock32 -lcomdlg32 -lole32 -lwinmm \
	 -lversion -lwininet -luser32 -lgdi32 -lpsapi -lkernel32 -lcrtdll \
	-ldsound -lsecur32

#############################################################################
# Gnuifier settings
#
AWK:=		gawk
GNUIFY:= $(PLATDIR)/win32/misc/gnuify

#############################################################################
# Tools to use
#
AR:= ar rc
CP:= cp
RM:= rm
DLLTOOL:=	dlltool
DLLWRAP:=	dllwrap
STRIP:=	strip
OBJCOPY:=	objcopy

#############################################################################
# RC settings
#
# Note: RC compiles the .rc files into linkable .o files
#
RC:=	 windres
RCFLAGS:= --include-dir $(PLATDIR)/win32/misc -D_WIN32

.SUFFIXES:
.SUFFIXES:	.ccg .cc .c .o .s .i .rc .res .cg .hg .ccg .cpp



#############################################################################
# Common build rules
#
default: print-settings init eitheror.exe mkNamedPrims.exe $(OBJDIR) $(VMEXE) $(CONSOLEVMEXE) $(DLLS) $(STRIPEXE) $(STRIPCONSOLEEXE)

# Do make init to allow make -n to function.
init:	$(OBJDIR) eitheror.exe mkNamedPrims.exe

print-settings:
	@echo ---------------- Makefile settings ------------------
	@echo VPATH=$(VPATH)
	@echo INCLUDES=$(INCLUDES)
	@echo CFLAGS=$(CFLAGS)
	@echo INTERNAL_PLUGINS=$(INTERNAL_PLUGINS)
	@echo EXTERNAL_PLUGINS=$(EXTERNAL_PLUGINS)
	@echo LIBS=$(LIBS)
	@echo DLLS=$(DLLS)
	@echo -----------------------------------------------------

print-objects:
	@echo ---------------- Makefile objects ------------------
	@echo VMOBJ=$(VMOBJ)
	@echo -----------------------------------------------------

eitheror.exe: $(WIN32UTILDIR)/eitheror.c
	$(CC) -o $@ -O1 -mno-cygwin $<

mkNamedPrims.exe: $(WIN32UTILDIR)/mkNamedPrims.c
	$(CC) -o $@ -mconsole -mno-cygwin $<

$(BTOBJ):	$(WIN32MISCDIR)/btext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

$(ETOBJ):	$(WIN32MISCDIR)/etext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

vm:	$(VMEXE)

$(VMEXE): $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(LDFLAGS) -o $(VMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	nm --numeric-sort --defined-only -f bsd $(VMEXE) >$(VMMAP)

$(CONSOLEVMEXE): $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(CONSOLELDFLAGS) -o $(CONSOLEVMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	nm --numeric-sort --defined-only -f bsd $(CONSOLEVMEXE) >$(CONSOLEVMMAP)

$(STRIPEXE): $(VMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPEXE) $(VMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(VMEXE) $(STRIPEXE)

$(STRIPCONSOLEEXE): $(CONSOLEVMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPCONSOLEEXE) $(CONSOLEVMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(CONSOLEVMEXE) $(STRIPCONSOLEEXE)

$(OBJDIR):
	@-mkdir $(BLDDIR)
	mkdir $(OBJDIR)
	mkdir $(addprefix $(BLDDIR)/, $(INTERNAL_PLUGINS))
	mkdir $(addprefix $(BLDDIR)/, $(EXTERNAL_PLUGINS))

#############################################################################
# The exports for named primitives from Squeak (required by VM)
#
$(VMDEF) $(VMEXP) $(VMLIB): $(VMOBJ)
	$(DLLTOOL) --input-def $(VMDEFIN) --output-def $(OBJDIR)/$(VMDEF) --output-exp $(VMEXP) --output-lib $(OBJDIR)/$(VMLIB) $(VMOBJ)

#############################################################################
# Building plugins
#

.PHONY: FORCE

# Internal plugin.  Build as lib then link in lib
# Check for Makefile in win32 plugins directory otherwise use default Makefile
# N.B.  PLATDIR *must* be a relative path for this to work
$(OBJDIR)/%.lib:	FORCE
	@-mkdir $(BLDDIR)/$(*F)
	$(MAKE) $(MFLAGS) -C $(BLDDIR)/$(*F) \
		-f../../$(shell eitheror.exe $(PLATDIR)/win32/plugins/$(*F)/Makefile Makefile.plugin) \
		PLATDIR=../../$(PLATDIR) SRCDIR=../../$(SRCDIR) BASEDIR=../../$(BASEDIR) \
		LIBNAME=$(*F) XDEFS=-DSQUEAK_BUILTIN_PLUGIN \
		../../$(OBJDIR)/$(*F).lib

# External plugin.  Build as dll and copy to vm dir ($(OBJDIR)).
# Check for Makefile in win32 plugins directory otherwise use default Makefile
$(OBJDIR)/%.dll:	FORCE
	@-mkdir $(BLDDIR)/$(*F)
	$(MAKE) $(MFLAGS) -C $(BLDDIR)/$(*F) \
		-f../../$(shell eitheror.exe $(PLATDIR)/win32/plugins/$(*F)/Makefile Makefile.plugin) \
		PLATDIR=../../$(PLATDIR) SRCDIR=../../$(SRCDIR) BASEDIR=../../$(BASEDIR) \
		LIBNAME=$(*F) ../../$(OBJDIR)/$(*F).dll

FORCE:

#############################################################################
# Basic rules

$(OBJDIR)/%.o: %.c $(wildcard $(CROSSDIR)/*.h) $(wildcard $(WIN32DIR)/*.h) $(wildcard $(MAKERDIR)/*.h)
		$(CC) -o $@ $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

.c.s:
		$(CC) -S -o $@ -fverbose-asm -Wa,ah $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

gnu-interp.c:	interp.c $(GNUIFY)
		$(AWK) -f $(GNUIFY) $< > $(VMDIR)/$@

.rc.res:
		$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@

$(VMRES): $(BASEDIR)/$(VM).rc
	$(RC) $(RCFLAGS) -i $(BASEDIR)/$(VM).rc -o $(OBJDIR)/$@

resource.o:	$(VMRES)
		$(RC) $(RCFLAGS) -i $(OBJDIR)/$< -o $(OBJDIR)/$@

#############################################################################
# Extra specific dependencies
#

sqNamedPrims.h: plugins.int mkNamedPrims.exe
	./mkNamedPrims.exe $(INTERNAL_PLUGINS) > sqNamedPrims.h

$(OBJDIR)/sqNamedPrims.o:	sqNamedPrims.c sqNamedPrims.h

Squeak.res: $(BASEDIR)/Squeak.rc
	$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@

Croquet.res: $(BASEDIR)/Croquet.rc
	$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@
