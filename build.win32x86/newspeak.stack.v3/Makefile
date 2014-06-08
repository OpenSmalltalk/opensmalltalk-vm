#############################################################################
# Makefile for Win32 Stack Newspeak VM using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

#############################################################################
# Base definitions:
# default configuration from product, assert & debug
#
CONFIGURATION=product

# The name of the VM to build
VM:=nsvm
VM_NAME?=Newspeak Virtual Machine

#############################################################################
# Default locations
#
ifndef BASEDIR
BASEDIR:=.
endif

ifeq ("$(CONFIGURATION)","product")
BUILD:=build
else ifeq ("$(CONFIGURATION)","assert")
BUILD:=buildast
else
BUILD:=builddbg
endif
PLUGINSRCDIR:= ../../nscogsrc
VMSRCDIR:= ../../nsstacksrc
BLDDIR:= $(BASEDIR)/$(BUILD)
OBJDIR:= $(BLDDIR)/vm

# N.B. PLATDIR *must* be a relative path, see -f../../$(shell ./eitheror ... below
PLATDIR:=../../platforms
CROSSDIR:=$(PLATDIR)/Cross/vm
WIN32DIR:=$(PLATDIR)/win32/vm
MAKERDIR:=$(VMSRCDIR)/vm
WIN32MISCDIR:=$(PLATDIR)/win32/misc
WIN32UTILDIR:=$(PLATDIR)/win32/util

CROSSSRC:= $(wildcard $(CROSSDIR)/*.c) $(wildcard $(CROSSDIR)/*.cpp)
WIN32SRC:= $(wildcard $(WIN32DIR)/*.c) $(wildcard $(WIN32DIR)/*.cpp)
MAKERSRC:= $(MAKERDIR)/gcc3x-interp.c
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
VMDIR:= $(VMSRCDIR)/vm
VMOBJ:=	$(VMSRC:.c=.o)
VMOBJ:= $(addprefix $(OBJDIR)/,$(VMOBJ))

#LIBSRC:= $(wildcard *.c)
#LIBOBJ:= $(LIBSRC:.c=.o)

#############################################################################
# SqueakVM definitions
#
ifeq ("$(CONFIGURATION)","product")
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
CC:=gcc

# VM config flags.
ifeq ("$(CONFIGURATION)","product")
OFLAGS:= -D_MT -O2 -march=pentium4 -momit-leaf-frame-pointer -funroll-loops
NDEBUG:=-DNDEBUG # Define NDEBUG for production to exclude asserts
				 # include labels for profiling interpret
DEBUGVM=0
else ifeq ("$(CONFIGURATION)","assert")
OFLAGS:= -D_MT -O1 -march=pentium4 -fno-omit-frame-pointer
NDEBUG:=-D'VM_LABEL(foo) 0' # Exclude labels for debugging interpret
DEBUGVM=0
else
OFLAGS:= -D_MT -march=pentium4
NDEBUG:=-DNODBGPRINT=1 -D'VM_LABEL(foo)=0' -D'bzero(p,s)=__builtin_bzero((p),(s))'
DEBUGVM=1
endif

# Set minimum version to WindowsXP (see /cygwin/usr/include//w32api/w32api.h)
WINVER:=-D_WIN32_WINNT=0x0501 -DWINVER=0x0501
WINDEFS:=$(WINVER) -DWIN32 -DWIN32_FILE_SUPPORT -DNO_STD_FILE_SUPPORT

INCLUDEPATH:= -isystem/usr/include/mingw -I/usr/include/w32api
# define _MT to eliminate the inline versions of printf et al in mingw/stdio.h
NOBUILTIN:= -D_MT -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf
CFLAGS:= $(INCLUDEPATH) -msse2 -ggdb2 -mwindows -mthreads -mno-cygwin -mwin32 \
	-mno-rtd -mms-bitfields -mno-accumulate-outgoing-args $(OFLAGS) $(NOBUILTIN)
DEFS:=	-DMULTIPLEBYTECODESETS=1 -D'VM_NAME="$(VM_NAME)"' -DDEBUGVM=$(DEBUGVM) \
		$(WINDEFS) -DNO_ISNAN -DNO_SERVICE $(NDEBUG) -DLSB_FIRST -DX86 $(XDEFS)
XDEFS:=	-DSQUEAK_BUILTIN_PLUGIN
INCLUDES:= -I. -I$(VMDIR) -I$(WIN32DIR) -I$(CROSSDIR) -I$(DXDIR) $(XINC)

#############################################################################
# Linker settings
#
# Note: I had to use 'gcc' instead of 'ld' to prevent unresolved symbols
#       The switch '-mwindows' gives us a GUI app instead of a console app.
#		Newer cygwins want --export-all-symbols in place of --export-dynamic.
#
LD:=	 gcc
LDFLAGS:= -mno-cygwin -mwindows -Wl,--export-dynamic -L/usr/lib/mingw
CONSOLELDFLAGS:= -mno-cygwin -mconsole -Wl,--export-dynamic -L/usr/lib/mingw
#LDFLAGS:= -mno-cygwin -mwindows -Wl,--export-all-symbols -L/usr/lib/mingw
#CONSOLELDFLAGS:= -mno-cygwin -mconsole -Wl,--export-all-symbols -L/usr/lib/mingw
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
default: print-settings init $(VMEXE) $(CONSOLEVMEXE) $(DLLS) $(STRIPEXE) $(STRIPCONSOLEEXE)

product:;
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=product $(@,product=) default

assert:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=assert $(@,assert=) default

debug:
	$(MAKE) -f $(MAKEFILE_LIST) CONFIGURATION=debug $(@,debug=) default

# Do make init to allow make -n to function.
init:	$(OBJDIR) eitheror.exe mkNamedPrims.exe

cleanall:	clean cleanast cleandbg

clean:
	rm -rf sqNamedPrims.h eitheror.exe mkNamedPrims.exe build

cleanast:
	rm -rf sqNamedPrims.h eitheror.exe mkNamedPrims.exe buildast

cleandbg:
	rm -rf sqNamedPrims.h eitheror.exe mkNamedPrims.exe builddbg

print-settings:
	@echo ---------------- Makefile settings ------------------
	@echo CONFIGURATION=$(CONFIGURATION)
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
	$(CC) -o $@ -O1 -mconsole -mno-cygwin $<

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

ifneq ($STRIPEXE,)
$(STRIPEXE): $(VMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPEXE) $(VMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(VMEXE) $(STRIPEXE)

$(STRIPCONSOLEEXE): $(CONSOLEVMEXE)
	$(STRIP) --strip-unneeded -o $(STRIPCONSOLEEXE) $(CONSOLEVMEXE)
	$(OBJCOPY) --add-gnu-debuglink=$(CONSOLEVMEXE) $(STRIPCONSOLEEXE)
endif

$(OBJDIR):
	@-mkdir $(BLDDIR)
	mkdir $(OBJDIR)
ifneq ($(INTERNAL_PLUGINS),)
	mkdir $(addprefix $(BLDDIR)/, $(INTERNAL_PLUGINS))
endif
ifneq ($(EXTERNAL_PLUGINS),)
	mkdir $(addprefix $(BLDDIR)/, $(EXTERNAL_PLUGINS))
endif

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
	$(MAKE) $(MFLAGS) -C $(BLDDIR)/$(*F) BUILD=$(BUILD) \
		-f../../$(shell ./eitheror.exe $(PLATDIR)/win32/plugins/$(*F)/Makefile Makefile.plugin) \
		PLATDIR=../../$(PLATDIR) BASEDIR=../../$(BASEDIR) \
		PLUGINSRCDIR=../../$(PLUGINSRCDIR) VMSRCDIR=../../$(VMSRCDIR) \
		COGDEFS="" LIBNAME=$(*F) XDEFS=-DSQUEAK_BUILTIN_PLUGIN \
		../../$(OBJDIR)/$(*F).lib

# External plugin.  Build as dll and copy to vm dir ($(OBJDIR)).
# Check for Makefile in win32 plugins directory otherwise use default Makefile
$(OBJDIR)/%.dll:	FORCE
	@-mkdir $(BLDDIR)/$(*F)
	$(MAKE) $(MFLAGS) -C $(BLDDIR)/$(*F) BUILD=$(BUILD) \
		-f../../$(shell ./eitheror.exe $(PLATDIR)/win32/plugins/$(*F)/Makefile Makefile.plugin) \
		PLATDIR=../../$(PLATDIR) BASEDIR=../../$(BASEDIR) \
		PLUGINSRCDIR=../../$(PLUGINSRCDIR) VMSRCDIR=../../$(VMSRCDIR) \
		COGDEFS="" LIBNAME=$(*F) ../../$(OBJDIR)/$(*F).dll

FORCE:

#############################################################################
# Basic rules
#
$(OBJDIR)/%.o: %.c $(wildcard $(CROSSDIR)/*.h) $(wildcard $(WIN32DIR)/*.h) $(wildcard $(MAKERDIR)/*.h)
	$(CC) -o $@ $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

.c.s:
	$(CC) -S -o $@ -fverbose-asm -Wa,ah $(CFLAGS) $(INCLUDES) $(DEFS) -c $<

.rc.res:
	$(RC) $(RCFLAGS) -i $< -o $(OBJDIR)/$@

$(VMRES): $(BASEDIR)/$(VM).rc
	$(RC) $(RCFLAGS) -i $(BASEDIR)/$(VM).rc -o $(OBJDIR)/$@
	$(CP) $(VM).exe.manifest $(OBJDIR)

resource.o:	$(VMRES)
	$(RC) $(RCFLAGS) -i $(OBJDIR)/$< -o $(OBJDIR)/$@

#############################################################################
# Extra specific dependencies
#
sqNamedPrims.h: plugins.int mkNamedPrims.exe
	./mkNamedPrims.exe $(INTERNAL_PLUGINS) > sqNamedPrims.h

$(OBJDIR)/sqNamedPrims.o:	sqNamedPrims.c sqNamedPrims.h
