####################################################################################
# Makefile for Win32 Cog Spur Squeak VM using either gcc and cygwin or MSVC and LLVM
# Do make init to allow make -n to function.
####################################################################################

VM:=Squeak
VMSRCDIR:=../../../src/spur64.cog

# This variable is set by VS Native Tools Command Prompts, not for cygwin wins
VSCMD_ARG_HOST_ARCH := $(shell echo $$VSCMD_ARG_HOST_ARCH)
ifeq ($(VSCMD_ARG_HOST_ARCH),)
	# We expect a clang to be in any but the default MSYS2 environment. For
	MSYS2_CLANG_PATH := $(shell command -v clang)
	ifeq ($(MSYS2_CLANG_PATH),)
		include ../common/Makefile.WinSDK
	else
		include ../common/Makefile
	endif
else
	include ../common/Makefile.msvc
endif
