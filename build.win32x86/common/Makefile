#############################################################################
# COmmon Makefile for Win32 VM using gcc-3.4.x, cygwin and gnu make
# Do make init to allow make -n to function.
#############################################################################

#############################################################################
# Parameters:
# VM the name of the exe to build, defaults to Squeak (=> Squeak.exe)
# VM_NAME the name the VM will print when reporting, defaults to $(VM)
# VMSRCDIR the directory containing the interpreter, optional cogit and interp.h
# CONFIGURATION configuration of VM to build from product, assert & debug
# THREADING whether to build a multi-threaded FFI VM

VM?=Squeak
VM_NAME?=$(VM)
CONFIGURATION=product
THREADING=single

# Is this a Croquet VM (defaults to OGL instead of D3D)?
CROQUET:=-DCROQUET

#############################################################################
# Default locations
#

ifeq ($(THREADING),multi)
	ifeq ($(CONFIGURATION),product)
		BUILD:=buildmt
	else ifeq ($(CONFIGURATION),assert)
		BUILD:=buildmtast
	else
		BUILD:=buildmtdbg
	endif
else
	ifeq ($(CONFIGURATION),product)
		BUILD:=build
	else ifeq ($(CONFIGURATION),assert)
		BUILD:=buildast
	else
		BUILD:=builddbg
	endif
endif
$(shell mkdir -p deps >/dev/null) # deps is the dependencies directory
PLUGINSRCDIR:= ../../src
OBJDIR:= $(BUILD)/vm

PLATDIR:=../../platforms
CROSSDIR:=$(PLATDIR)/Cross/vm
WIN32DIR:=$(PLATDIR)/win32/vm
WIN32MISCDIR:=$(PLATDIR)/win32/misc
WIN32UTILDIR:=$(PLATDIR)/win32/util

CROSSSRC:= $(wildcard $(CROSSDIR)/*.c) $(wildcard $(CROSSDIR)/*.cpp)
WIN32SRC:= $(wildcard $(WIN32DIR)/*.c) $(wildcard $(WIN32DIR)/*.cpp)
ifeq ($(THREADING),multi)
MAKERSRC:= $(wildcard $(VMSRCDIR)/gcc3x-*interpmt.c $(VMSRCDIR)/cogit.c)
else
MAKERSRC:= $(wildcard $(VMSRCDIR)/gcc3x-*interp.c $(VMSRCDIR)/cogit.c)
endif
VMSRC:= $(notdir $(MAKERSRC) $(WIN32SRC) $(CROSSSRC))

VPATH:= $(VMSRCDIR) $(WIN32DIR) $(CROSSDIR)

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
VMOBJ:=	$(VMSRC:.c=.o)
VMOBJ:= $(addprefix $(OBJDIR)/,$(VMOBJ))

#############################################################################
# SqueakVM definitions
#
ifeq ($(CONFIGURATION),product)
VMEXE:=  $(OBJDIR)/$(VM)Unstripped.exe
CONSOLEVMEXE:=  $(OBJDIR)/$(VM)ConsoleUnstripped.exe
STRIPEXE:=  $(OBJDIR)/$(VM).exe
STRIPCONSOLEEXE:=  $(OBJDIR)/$(VM)Console.exe
else
VMEXE:=  $(OBJDIR)/$(VM).exe
CONSOLEVMEXE:=  $(OBJDIR)/$(VM)Console.exe
STRIPEXE:=
STRIPCONSOLEEXE:=
endif
VMDEF:=	$(VM).def
VMEXP:=	$(OBJDIR)/$(VM).exp
VMMAP:=	$(OBJDIR)/$(VM).map
CONSOLEVMMAP:=	$(OBJDIR)/$(VM)Console.map
VMLIB:=	$(VM).lib
VMRES:=	$(VM).res
VMDEFIN:=$(VM).def.in
BTOBJ:= $(OBJDIR)/btext.o
ETOBJ:= $(OBJDIR)/etext.o


.PRECIOUS: mkNamedPrims.exe

#############################################################################
# DirectX definitions
#
DXDIR:=     $(PLATDIR)/win32/third-party/dx9sdk/Include

#############################################################################
# C compiler settings (gcc-3.4.4 cygwin 19.24)
#
CC:=gcc

# VM config flags.
ifeq ($(CONFIGURATION),product)
OFLAGS:= -D_MT -O2 -march=pentium4 -momit-leaf-frame-pointer -funroll-loops
NDEBUG:=-DNDEBUG -D'VM_LABEL(foo)=0' # Define NDEBUG for production to exclude asserts
DEBUGVM=0
else ifeq ($(CONFIGURATION),assert)
OFLAGS:= -D_MT -O1 -march=pentium4 -fno-omit-frame-pointer
DEBUGVM=0
NDEBUG:=-DAllocationCheckFiller=0xADD4E55 -D'VM_LABEL(foo)=0'
else
OFLAGS:= -D_MT -march=pentium4
DEBUGVM=1
NDEBUG:=-DAllocationCheckFiller=0xADD4E55 -D'VM_LABEL(foo)=0'
endif

ifeq ($(THREADING),multi)
COGDEFS:=-DCOGMTVM=1 -DDEBUGVM=$(DEBUGVM)
else
COGDEFS:=-DCOGMTVM=0 -DDEBUGVM=$(DEBUGVM)
endif

# Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)
WINVER:=-D_WIN32_WINNT=0x0501 -DWINVER=0x0501

INCLUDEPATH:= -isystem/usr/include/mingw -I/usr/include/w32api
# define _MT to eliminate the inline versions of printf et al in mingw/stdio.h
NOBUILTIN:= -D_MT -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf
CFLAGS:= $(INCLUDEPATH) -msse2 -ggdb2 -mwindows -mthreads -mno-cygwin -mwin32 \
	-mno-rtd -mms-bitfields -mno-accumulate-outgoing-args $(OFLAGS) $(NOBUILTIN)
TZ:=$(shell date +%Z)
DEFS:=	$(COGDEFS) $(WINVER) -DWIN32 -DWIN32_FILE_SUPPORT -DNO_ISNAN \
		-DNO_SERVICE -DNO_STD_FILE_SUPPORT -D'TZ="$(TZ)"' \
		$(NDEBUG) -DLSB_FIRST -D'VM_NAME="$(VM_NAME)"' -DX86 $(XDEFS) $(CROQUET)
XDEFS:=	-DSQUEAK_BUILTIN_PLUGIN
INCLUDES:= -I. -I$(VMSRCDIR) -I$(WIN32DIR) -I$(CROSSDIR) -I$(DXDIR) $(XINC)

#############################################################################
# Linker settings
#
# Note: I had to use 'gcc' instead of 'ld' to prevent unresolved symbols
#       The switch '-mwindows' gives us a GUI app instead of a console app.
#		Newer cygwins want --export-all-symbols in place of --export-dynamic.
#
LD:=	 gcc
EXPORT:=--export-dynamic
#EXPORT:=--export-all-symbols
BASELDFLAGS:=-mno-cygwin -mthreads -Wl,--large-address-aware,$(EXPORT) -L/usr/lib/mingw
LDFLAGS:= -mwindows $(BASELDFLAGS)
CONSOLELDFLAGS:= -mconsole $(BASELDFLAGS)
STDLIBS:= -lddraw -ldinput -lopengl32 -lwsock32 -lcomdlg32 -lole32 -lwinmm \
	-lversion -lwininet -luser32 -lgdi32 -lpsapi -lkernel32 -lcrtdll \
	-ldsound -lsecur32

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
SVNREV:= $(shell sed -e "s/^static.*SvnRawRevisionString.*Rev: \([0-9][0-9]*\).*/\\1/p" -e d $(PLATDIR)/Cross/vm/sqSCCSVersion.h)
RCFLAGS:= --include-dir $(PLATDIR)/win32/misc -D_WIN32 -DFILEVERSIONVALUES=4,0,$(SVNREV),0 '-DFILEVERSIONSTRING=\"4.0.$(SVNREV)\\0\"'

.SUFFIXES:
.SUFFIXES:	.ccg .cc .c .o .s .i .rc .res .cg .hg .ccg .cpp



#############################################################################
# Common build rules
#
default: print-settings init $(VMEXE) $(CONSOLEVMEXE) $(DLLS) $(STRIPEXE) $(STRIPCONSOLEEXE) nukelibs

svnver:
	echo $(RC) $(RCFLAGS)

productmt:;
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=product THREADING=multi $(@,product=) default

product:;
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=product THREADING=single $(@,product=) default

assertmt:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=assert THREADING=multi $(@,assert=) default

assert:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=assert THREADING=single $(@,assert=) default

debugmt:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=debug THREADING=multi $(@,debug=) default

debug:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=debug THREADING=single $(@,debug=) default

# Do make init to allow make -n to function.
init:	$(OBJDIR) mkNamedPrims.exe

cleanall:	clean cleanmt cleanast cleanmtast cleandbg cleanmtdbg

clean:
	rm -rf sqNamedPrims.h mkNamedPrims.exe build

cleanmt:
	rm -rf sqNamedPrims.h mkNamedPrims.exe buildmt

cleanast:
	rm -rf sqNamedPrims.h mkNamedPrims.exe buildast

cleanmtast:
	rm -rf sqNamedPrims.h mkNamedPrims.exe buildmtast

cleandbg:
	rm -rf sqNamedPrims.h mkNamedPrims.exe builddbg

cleanmtdbg:
	rm -rf sqNamedPrims.h mkNamedPrims.exe buildmtdbg

nukelibs:
	rm $(LIBS)

print-settings:
	@echo ---------------- Makefile settings ------------------
	@echo CONFIGURATION=$(CONFIGURATION)
	@echo THREADING=$(THREADING)
	@echo VPATH=$(VPATH)
	@echo INCLUDES=$(INCLUDES)
	@echo CFLAGS=$(CFLAGS)
	@echo INTERNAL_PLUGINS=$(INTERNAL_PLUGINS)
	@echo EXTERNAL_PLUGINS=$(EXTERNAL_PLUGINS)
	@echo OBJDIR=$(OBJDIR)
	@echo LIBS=$(LIBS)
	@echo DLLS=$(DLLS)
	@echo -----------------------------------------------------

print-objects:
	@echo ---------------- Makefile objects ------------------
	@echo VMOBJ=$(VMOBJ)
	@echo -----------------------------------------------------

mingw32ver.exe: $(WIN32UTILDIR)/mingw32ver.c
	$(CC) -o $@ -O1 -mconsole -mno-cygwin $<

mkNamedPrims.exe: $(WIN32UTILDIR)/mkNamedPrims.c
	$(CC) -o $@ -mconsole -mno-cygwin $<

$(BTOBJ):	$(WIN32MISCDIR)/btext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

$(ETOBJ):	$(WIN32MISCDIR)/etext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

vm:	$(VMEXE)

$(VMEXE): $(OBJDIR) $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(LDFLAGS) -o $(VMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	nm --numeric-sort --defined-only -f bsd $(VMEXE) >$(VMMAP)

$(CONSOLEVMEXE): $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(CONSOLELDFLAGS) -o $(CONSOLEVMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	nm --numeric-sort --defined-only -f bsd $(CONSOLEVMEXE) >$(CONSOLEVMMAP)

ifneq ($STRIPEXE,)
$(STRIPEXE): $(VMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPEXE) $(VMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(VMEXE) $(STRIPEXE)

$(STRIPCONSOLEEXE): $(CONSOLEVMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPCONSOLEEXE) $(CONSOLEVMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(CONSOLEVMEXE) $(STRIPCONSOLEEXE)
endif

$(OBJDIR):
	@-mkdir $(BUILD)
	mkdir $(OBJDIR)
ifneq ($(INTERNAL_PLUGINS),)
	mkdir $(addprefix $(BUILD)/, $(INTERNAL_PLUGINS))
endif
ifneq ($(EXTERNAL_PLUGINS),)
	mkdir $(addprefix $(BUILD)/, $(EXTERNAL_PLUGINS))
endif

#############################################################################
# The exports for named primitives from Squeak (required by VM)
#
$(VMDEF) $(VMEXP) $(VMLIB): $(VMOBJ)
	$(DLLTOOL) --input-def $(VMDEFIN) --output-def $(OBJDIR)/$(VMDEF) --output-exp $(VMEXP) --output-lib $(OBJDIR)/$(VMLIB) $(VMOBJ)

#############################################################################
# Building plugins
#

.PHONY: $(OBJDIR)/%.lib $(OBJDIR)/%.dll

# Check for Makefile in win32 plugins directory otherwise use default Makefile
plugin-makefile = $(firstword $(realpath \
					$(PLATDIR)/win32/plugins/$(*F)/Makefile.plugin \
					../common/Makefile.plugin))

# Internal plugin.  Build as lib then link in lib
$(OBJDIR)/%.lib: $(call plugin-makefile,$(*F))
	@-mkdir $(BUILD)/$(*F)
	$(MAKE) $(MFLAGS) CONFIGURATION=$(CONFIGURATION) BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		PLATDIR=$(PLATDIR) PLUGINSRCDIR=$(PLUGINSRCDIR) VMSRCDIR=$(VMSRCDIR) \
		LIBNAME=$(*F) COGDEFS="$(COGDEFS)" XDEFS=-DSQUEAK_BUILTIN_PLUGIN \
		$(OBJDIR)/$(*F).lib

# External plugin.  Build as dll and copy to vm dir ($(OBJDIR)).
$(OBJDIR)/%.dll: $(call plugin-makefile,$(*F))
	@-mkdir $(BUILD)/$(*F)
	$(MAKE) $(MFLAGS) CONFIGURATION=$(CONFIGURATION) BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		PLATDIR=$(PLATDIR) PLUGINSRCDIR=$(PLUGINSRCDIR) VMSRCDIR=$(VMSRCDIR) \
		COGDEFS="$(COGDEFS)" LIBNAME=$(*F) $(OBJDIR)/$(*F).dll

#############################################################################
# Basic rules
#
include ../common/Makefile.rules

$(VMRES): $(VM).rc
	$(RC) $(RCFLAGS) -i $(VM).rc -o $(OBJDIR)/$@
	$(CP) $(VM).exe.manifest $(OBJDIR)
	$(CP) $(VM).exe.manifest $(OBJDIR)/$(VM)Console.exe.manifest

resource.o:	$(VMRES)
	$(RC) $(RCFLAGS) -i $(OBJDIR)/$< -o $(OBJDIR)/$@

#############################################################################
# Extra specific dependencies
#
sqNamedPrims.h: plugins.int mkNamedPrims.exe
	./mkNamedPrims.exe $(INTERNAL_PLUGINS) > sqNamedPrims.h

$(OBJDIR)/sqNamedPrims.o:	sqNamedPrims.c sqNamedPrims.h
