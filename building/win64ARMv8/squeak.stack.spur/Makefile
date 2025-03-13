######################################################################################
# Makefile for Win32 Stack Spur Squeak VM using either gcc and cygwin, or MSVC and LLVM.
# Do make init to allow make -n to function.
######################################################################################

VM:=Squeak
VMSRCDIR:=../../../src/spur64.stack

# This variable is set by VS Native Tools Command Prompts, not for cygwin wins
VSCMD_ARG_HOST_ARCH := $(shell echo $$VSCMD_ARG_HOST_ARCH)
ifeq ($(VSCMD_ARG_HOST_ARCH),)
include ../common/Makefile
else
include ../common/Makefile.msvc
endif
