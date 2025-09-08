#############################################################################
# Common Makefile for Win64 VM using LLVM/Clang compiler, MSYS2 toolchain,
# and mingw-w64 for building a native Windows application.
#
# Visit: https://www.msys2.org/
# Visit: https://www.mingw-w64.org/
#
# Make sure to install Clang via MSYS2 pacman to get a compiler that targets
# *-w64-windows-gnu . Other pre-built Clang bundles for Windows will target
# *-pc-windows-msvc . See Makefile.WinSDK for the MSVC toolchain.
#
# RECOMMENDED: Start MSYS2/MINGW64 environment, run "mvm" script.
#
# Copyright (c) Andreas Raab, Eliot Miranda, Marcel Taeumel, et al. 
# Copyright (c) 2025 Hasso Plattner Institute, University of Potsdam, Germany
#
# Do make init to allow make -n to function.
#############################################################################

# Use SDKPREFIX configure custom build environments (e.g., .WinSDK). There
# are customization hooks for .rules, .rules.*, .tools, .tools.*, and .plugin
SDKPREFIX?=

#############################################################################
# Parameters:
# VM the name of the exe to build, defaults to Squeak (=> Squeak.exe)
# VM_NAME the name the VM will print when reporting, defaults to $(VM)
# VMSRCDIR the directory containing the interpreter, optional cogit and interp.h
# CONFIGURATION configuration of VM to build from product, assert & debug
# THREADING whether to build a multi-threaded FFI VM
# COGDEFS supply any command-line defines to use, and may be null.

.PHONY: all
all: default

VM?=Squeak
VM_NAME?=$(VM)
export VM VM_NAME CONFIGURATION COGDEFS

# This Makefile has a two-pass initialization scheme for COGDEFS, which
# sets VM-specific compilation flags such as for multi-threaded and
# debug builds. We encode this by checking whether CONFIGURATION was 
# provided from the outer invocation. We want to avoid expanding COGDEFS
# with the wrong default values in the first, preparatory pass.
ifeq ($(CONFIGURATION),)
	IS_PREPARING:=true
else
	IS_PREPARING:=false
endif

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

PLUGINSRCDIR:= ../../../src
export PLUGINSRCDIR
OBJDIR:= $(BUILD)/vm

PLATDIR:=../../../platforms
export PLATDIR
CROSSDIR:=$(PLATDIR)/Cross/vm
TPDIR:=$(PLATDIR)/Cross/third-party
WIN32DIR:=$(PLATDIR)/win32/vm
WIN32PLUGINSDIR:=$(PLATDIR)/win32/plugins
WIN32MISCDIR:=$(PLATDIR)/win32/misc
WIN32UTILDIR:=$(PLATDIR)/win32/util

CROSSSRC:= $(wildcard $(CROSSDIR)/*.c) $(wildcard $(CROSSDIR)/*.cpp)
WIN32SRC:= $(wildcard $(WIN32DIR)/*.c) $(wildcard $(WIN32DIR)/*.cpp)
ifeq ($(THREADING),multi)
MAKERSRC:= $(wildcard $(VMSRCDIR)/[ci]*terpmt.c $(VMSRCDIR)/cogit.c)
else
MAKERSRC:= $(wildcard $(VMSRCDIR)/[ci]*terp.c $(VMSRCDIR)/cogit.c)
endif
VMSRC:= $(notdir $(MAKERSRC) $(WIN32SRC) $(CROSSSRC))

VPATH:= $(VMSRCDIR) $(WIN32DIR) $(CROSSDIR)

#############################################################################
# Toolchain (incl. paths to tools and flags for tools)
#
include ../common/Makefile$(SDKPREFIX).tools
include ../common/Makefile$(SDKPREFIX).tools.print
include ../common/Makefile$(SDKPREFIX).tools.flags
include ../common/Makefile$(SDKPREFIX).tools.defs

#############################################################################
$(shell $(MKDIR) deps >/dev/null) # deps is the dependencies directory

#############################################################################
# The internal (.lib) and external (.dll) plugins
#
include plugins.ext
include plugins.int

LIBS:= $(addprefix $(OBJDIR)/, $(addsuffix .lib, $(INTERNAL_PLUGINS)))
DLLS:= $(addprefix $(OBJDIR)/, $(addsuffix .dll, $(EXTERNAL_PLUGINS)))

ifdef BIT_IDENTICAL_FLOATING_POINT
LIBS:=$(BUILD)/fdlibm/libm.a $(LIBS)
export BIT_IDENTICAL_FLOATING_POINT
endif

.PHONY: libs dlls

libs: $(LIBS)
dlls: $(DLLS)

#############################################################################
# The third-party libraries
#
ifneq ($(THIRDPARTYLIBS),)
include ../common/Makefile$(SDKPREFIX).lib.extra
THIRDPARTYPREREQS:=$(THIRDPARTYCACHEDIR) $(THIRDPARTYOUTDIR) 
endif

#############################################################################
# Generic VM source file definitions
#
VMOBJ:=	$(VMSRC:.c=.o)
VMOBJ:= $(addprefix $(OBJDIR)/,$(VMOBJ))

#############################################################################
# SqueakVM definitions
#
VMEXE:=  $(OBJDIR)/$(VM).exe
CONSOLEVMEXE:=  $(OBJDIR)/$(VM)Console.exe
VMDEF:=	$(VM).def
VMMAP:=	$(OBJDIR)/$(VM).map
CONSOLEVMMAP:=	$(OBJDIR)/$(VM)Console.map
VMLIB:=	$(VM).lib
VMRES:=	$(VM).res
VMDEFIN:=$(VM).def.in
BTOBJ:= $(OBJDIR)/btext.o
ETOBJ:= $(OBJDIR)/etext.o
JMPASM:=_setjmp-$(ARCH).asm
JMPOBJ:=$(OBJDIR)/_setjmp-$(ARCH).o

.PRECIOUS: mkNamedPrims.exe

INCLUDES:= -I. -I$(VMSRCDIR) -I$(WIN32DIR) -I$(CROSSDIR) $(XINC)

.SUFFIXES:
.SUFFIXES:	.ccg .cc .c .o .s .i .rc .res .cg .hg .ccg .cpp

#############################################################################
# Common build rules
#
include ../common/Makefile$(SDKPREFIX).rules
include ../common/Makefile$(SDKPREFIX).rules.vm

default: product # ensure two-pass initialization, see below
defaultBuild: print-tools print-settings init vm vm-extra $(APPPOST)

vm:	libs $(VMEXE) $(CONSOLEVMEXE) dlls

svnver:
	echo $(RC) $(RCFLAGS)

productmt:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=product THREADING=multi $(@,product=) defaultBuild

product:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=product THREADING=single $(@,product=) defaultBuild

assertmt:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=assert THREADING=multi $(@,assert=) defaultBuild

assert:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=assert THREADING=single $(@,assert=) defaultBuild

debugmt:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=debug THREADING=multi $(@,debug=) defaultBuild

debug:
	$(MAKE) -f $(firstword $(MAKEFILE_LIST)) CONFIGURATION=debug THREADING=single $(@,debug=) defaultBuild

# Do make init to allow make -n to function.
init: $(THIRDPARTYPREREQS) $(OBJDIR) mkNamedPrims.exe

cleanall:	clean cleanmt cleanast cleanmtast cleandbg cleanmtdbg

clean:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGF build deps

cleanmt:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGTF buildmt deps

cleanast:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGA buildast deps

cleanmtast:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGTA buildmtast deps

cleandbg:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGD builddbg deps

cleanmtdbg:
	$(RM) -rf sqNamedPrims.h mkNamedPrims.* LOGTD buildmtdbg deps

nukelibs:
	$(RM) $(LIBS)

nukedlls:
	$(RM) $(DLLS)

.PHONY : print-settings

print-settings:
	$(info ---------------- Makefile settings ------------------)
	$(info CONFIGURATION=$(CONFIGURATION))
	$(info THREADING=$(THREADING))
	$(info VPATH=$(VPATH))
	$(info INCLUDES=$(INCLUDES))
	$(info CFLAGS=$(CFLAGS))
	$(info DEFS=$(DEFS))
	$(info INTERNAL_PLUGINS=$(INTERNAL_PLUGINS))
	$(info EXTERNAL_PLUGINS=$(EXTERNAL_PLUGINS))
	$(info OBJDIR=$(OBJDIR))
	$(info LIBS=$(LIBS))
	$(info DLLS=$(DLLS))
	$(info -----------------------------------------------------)

.PHONY : print-objects

print-objects:
	$(info ---------------- Makefile objects ------------------)
	$(info VMOBJ=$(VMOBJ))
	$(info -----------------------------------------------------)

ignore := $(addsuffix .%, $(basename $(wildcard $(BUILD)/vm/*.ignore)))

$(BTOBJ):	$(WIN32MISCDIR)/btext.c
	$(CC) -c $< -fomit-frame-pointer -Os -o $@

$(ETOBJ):	$(WIN32MISCDIR)/etext.c
	$(CC) -c $< -fomit-frame-pointer -Os -o $@

$(JMPOBJ):	$(WIN32MISCDIR)/$(JMPASM)
	$(CC) -c $< -o $@

$(OBJDIR):
	@-$(MKDIR) $(BUILD)
	$(MKDIR) $(OBJDIR)
ifneq ($(INTERNAL_PLUGINS),)
	$(MKDIR) $(addprefix $(BUILD)/, $(INTERNAL_PLUGINS))
endif
ifneq ($(EXTERNAL_PLUGINS),)
	$(MKDIR) $(addprefix $(BUILD)/, $(EXTERNAL_PLUGINS))
endif

#############################################################################
# Building plugins
#

.PHONY: $(OBJDIR)/%.lib $(OBJDIR)/%.dll
.PHONY: always
# Check for Makefile in win32 plugins directory otherwise use default Makefile
plugin-makefile = $(realpath $(firstword $(wildcard $(WIN32PLUGINSDIR)/$(1)/Makefile$(SDKPREFIX).plugin ../common/Makefile$(SDKPREFIX).plugin)))

# Internal plugin.  Build as lib then link in lib
$(OBJDIR)/%.lib: always
	$(info WILDCARD $(*F): $(wildcard $(BUILD)/$(*F)/*.o))
	@-$(MKDIR) $(BUILD)/$(*F)
	$(RM) -f $(BUILD)/vm/$(*F).ignore
	$(MAKE) $(MFLAGS) $(SUBMFLAGS) -I../common BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		LIBNAME=$(*F) INTERNAL_PLUGIN=1 VMSRCDIR=$(VMSRCDIR) \
		COGDEFS="$(COGDEFS) -DSQUEAK_BUILTIN_PLUGIN=$(*F)" $(OBJDIR)/$(*F).lib

# External plugin.  Build as dll and copy to vm dir ($(OBJDIR)).
$(OBJDIR)/%.dll: always
	$(info WILDCARD $(*F): $(wildcard $(BUILD)/$(*F)/*.o))
	@-$(MKDIR) $(BUILD)/$(*F)
	$(RM) -f $(BUILD)/$(*F).ignore
	$(MAKE) $(MFLAGS) $(SUBMFLAGS) -I../common BUILD=$(BUILD) \
		-f $(call plugin-makefile,$(*F)) \
		LIBNAME=$(*F) EXTERNAL_PLUGIN=1 VMSRCDIR=$(VMSRCDIR) \
		JMPOBJ=$(JMPOBJ) VMLIB=$(OBJDIR)/$(VMLIB) \
		COGDEFS="$(COGDEFS) -DSQUEAK_EXTERNAL_PLUGIN=$(*F)" $(OBJDIR)/$(*F).dll

$(BUILD)/fdlibm/libm.a:
	@-$(MKDIR) $(@D)
	$(MAKE) CC='$(CC)' CFLAGS="$(CFLAGS) -D_IEEE_LIBM" -C $(@D) \
		TP=../../$(TPDIR) -f ../../$(TPDIR)/fdlibm/Makefile.remote


#############################################################################
# Extra specific dependencies
#
sqNamedPrims.h: plugins.int mkNamedPrims.exe
	./mkNamedPrims.exe $(INTERNAL_PLUGINS) > sqNamedPrims.h

$(OBJDIR)/sqNamedPrims.o:	$(CROSSDIR)/sqNamedPrims.c sqNamedPrims.h
