#############################################################################
# Makefile for Win32 Stack Squeak VM using gcc-3.4.x and cygwin
# Do make init to allow make -n to function.
#############################################################################

VM:=Squeak
VMSRCDIR:=../../stacksrc/vm

# This variable is set by VS Native Tools Command Prompts, not for cygwin wins
VSCMD_ARG_HOST_ARCH := $(shell echo $$VSCMD_ARG_HOST_ARCH)
ifeq ($(VSCMD_ARG_HOST_ARCH),)
include ../common/Makefile
else
include ../common/Makefile.msvc
endif
