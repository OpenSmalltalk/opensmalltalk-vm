##############################################################################
# Makefile for Mac OS X Cog Spur Squeak Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

BIT_IDENTICAL_FLOATING_POINT=BIT_IDENTICAL_FLOATING_POINT

VMSRCDIR:= ../../../src/spur64.cog
SOURCEFILE:=SqueakV60.sources

ifeq ($(THREADING),multi)
COGDEFS:=-DPRINT_DL_ERRORS=1
endif

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app.squeak
