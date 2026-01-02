#############################################################################
# Makefile for Win32 Cog Spur Squeak VM using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

VM:=Squeak
VMSRCDIR:=../../../src/spur32.cog

# This variable is set by VS Native Tools Command Prompts, not for cygwin wins
VSCMD_ARG_HOST_ARCH := $(shell echo $$VSCMD_ARG_HOST_ARCH)
ifeq ($(VSCMD_ARG_HOST_ARCH),)
include ../common/Makefile
else
include ../common/Makefile.msvc
endif
