#############################################################################
# COmmon Makefile for Win32 VM using gcc, cygwin and gnu make
# Do make init to allow make -n to function.
#############################################################################

#############################################################################
# Parameters:
# VM the name of the exe to build, defaults to Squeak (=> Squeak.exe)
# VM_NAME the name the VM will print when reporting, defaults to $(VM)
# VMSRCDIR the directory containing the interpreter, optional cogit and interp.h
# CONFIGURATION configuration of VM to build from product, assert & debug
# THREADING whether to build a multi-threaded FFI VM

.PHONY: all
all: default

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
WIN32PLUGINSDIR:=$(PLATDIR)/win32/plugins
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
# DirectX definitions - NOT USED - superseded by mingw provided files
#
DXDIR:=     $(PLATDIR)/win32/third-party/dx9sdk/Include

#############################################################################
# Toolchain
#
include ../common/Makefile.tools
 
INCLUDES:= -I. -I$(VMSRCDIR) -I$(WIN32DIR) -I$(CROSSDIR) $(XINC)

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
	$(CC) -o $@ -O1 -mconsole -m64 $<

mkNamedPrims.exe: $(WIN32UTILDIR)/mkNamedPrims.c
	$(CC) -o $@ -mconsole -m64 $<

$(BTOBJ):	$(WIN32MISCDIR)/btext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

$(ETOBJ):	$(WIN32MISCDIR)/etext.c
	$(CC) -c -o $@ -fomit-frame-pointer -O2 $<

vm:	$(VMEXE)

$(VMEXE): $(OBJDIR) $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(LDFLAGS) -o $(VMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	$(NM) --numeric-sort --defined-only -f bsd $(VMEXE) >$(VMMAP)

$(CONSOLEVMEXE): $(VMOBJ) $(LIBS) $(VMEXP) resource.o $(BTOBJ) $(ETOBJ)
	$(CC) -o $(OBJDIR)/version.o $(CFLAGS) $(INCLUDES) $(DEFS) -c $(WIN32DIR)/version.c
	$(LD) $(CONSOLELDFLAGS) -o $(CONSOLEVMEXE) \
			$(BTOBJ) $(VMOBJ) $(VMEXP) $(OBJDIR)/resource.o $(LIBS) $(STDLIBS) $(ETOBJ)
	$(NM) --numeric-sort --defined-only -f bsd $(CONSOLEVMEXE) >$(CONSOLEVMMAP)

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
plugin-makefile = $(realpath $(firstword $(wildcard $(WIN32PLUGINSDIR)/$(1)/Makefile.plugin ../common/Makefile.plugin)))

# Internal plugin.  Build as lib then link in lib
$(OBJDIR)/%.lib: $(call plugin-makefile,$(*F))
	@-mkdir -p $(BUILD)/$(*F)
	$(MAKE) $(MFLAGS) BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		CONFIGURATION=$(CONFIGURATION) TOOLPREFIX=$(TOOLPREFIX) \
		PLATDIR=$(PLATDIR) PLUGINSRCDIR=$(PLUGINSRCDIR) VMSRCDIR=$(VMSRCDIR) \
		LIBNAME=$(*F) COGDEFS="$(COGDEFS)" XDEFS=-DSQUEAK_BUILTIN_PLUGIN \
		$(OBJDIR)/$(*F).lib

# External plugin.  Build as dll and copy to vm dir ($(OBJDIR)).
$(OBJDIR)/%.dll: $(call plugin-makefile,$(*F))
	@-mkdir -p $(BUILD)/$(*F)
	$(MAKE) $(MFLAGS) BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		CONFIGURATION=$(CONFIGURATION) TOOLPREFIX=$(TOOLPREFIX) \
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
