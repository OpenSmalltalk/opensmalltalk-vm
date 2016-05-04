##############################################################################
# Makefile for Mac OS X Sista Spur Squeak Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

VMSRCDIR:= ../../spursistasrc/vm
COGDEFS=-DIMMUTABILITY=1
SOURCEFILE:=SqueakV50.sources

APPPOST:=overwriteSqueakIcon

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app

# Replace the standard yellow VM icon with the blue one used for Sista VMs

overwriteSqueakIcon: $(APP)/Contents/Resources/Squeak.icns
	cp -p $(OSXDIR)/BlueSistaSqueak.icns $(APP)/Contents/Resources/Squeak.icns
