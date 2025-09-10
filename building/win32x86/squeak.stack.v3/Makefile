####################################################################################
# Makefile for Win32 Cog Spur Squeak VM using LLVM/Clang
# Do make init to allow make -n to function.
####################################################################################

VM:=Squeak
VMSRCDIR:=../../../src/v3.stack

# This variable is set by VS Native Tools Command Prompts
ifeq ($(VSCMD_ARG_HOST_ARCH),)
	ifeq ($(MSYSTEM),MSYS)
		# In a generic MSYS2 environment, compile against WinSDK
		include ../common/Makefile.WinSDK
	else
		# In other envs (e.g. MINGW32 or CLANG32), compile against MinGW
		include ../common/Makefile
	endif
else
	# Legacy. All *.msvc.* makefiles should be removed at some point.
	include ../common/Makefile.msvc
# 	include ../common/Makefile.WinSDK
endif
