#############################################################################
# Common Makefile for Win64 VM using LLVM/Clang compiler, MSYS2 toolchain,
# and mingw-w64 for building a native Windows application.
#
# Copyright (c) 2025 Hasso Plattner Institute, University of Potsdam, Germany
#
#############################################################################

# See sdkddkver.h from Windows SDK or w32api.h from mingw-w64
#  Windows XP  ... 0x0501
#  Windows 7   ... 0x0601
#  Windows 8   ... 0x0602
#  Windows 10  ... 0x0A00
WINVER:=-D_WIN32_WINNT=0x0501 -DWINVER=0x0501

#############################################################################
# DEFS
#

# Several versions of clang (all versions from 14 through 18 as of this writing)
# generate incorrect code for spur segment storage
#	(return:restoringObjectsIn:savedFirstFields:and:savedHashes:)
# unless USE_INLINE_MEMORY_ACCESSORS is set.
MEMACCESS:=-DUSE_INLINE_MEMORY_ACCESSORS=1

DEFS:=-D$(VM)VM=1 $(COGDEFS) $(MEMACCESS) $(WINVER) \
		-DNO_ISNAN -DNO_SERVICE \
		$(NDEBUG) -DLSB_FIRST -D'VM_NAME="$(VM_NAME)"' $(XDEFS) $(CROQUET)

# Every clang for Windows (i.e. *-pc-windows-msvc or *-w64-windows-gnu) already
# defines WIN32, WIN64, etc. So, this might just be historical overhead.
DEFS:=$(DEFS) -DWIN32=1 -D_WIN32=1 -DWIN64=1 -D_WIN64=1

#!#! UNICODE applies to API calls, _UNICODE to string representation, so one
#!#! must define both.
DEFS:=$(DEFS) -DUNICODE=1 -D_UNICODE=1

