####################################################################################
# Makefile for Win64ARMv8 Cog Spur Squeak VM using LLVM/Clang
# Do make init to allow make -n to function.
####################################################################################

VM:=Squeak
VMSRCDIR:=../../../src/spur64.cog

# This variable is set by VS Native Tools Command Prompts
ifeq ($(VSCMD_ARG_HOST_ARCH),)
	ifeq ($(MSYSTEM),MSYS)
		# In a generic MSYS2 environment, compile against WinSDK
		include ../common/Makefile.WinSDK
	else
		# In other envs (e.g. CLANGARM64), compile against MinGW
		include ../common/Makefile
	endif
else
	# Legacy. All *.msvc.* makefiles should be removed at some point.
	include ../common/Makefile.msvc
# 	include ../common/Makefile.WinSDK
endif
