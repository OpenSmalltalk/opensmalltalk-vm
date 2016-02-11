##############################################################################
# Makefile for Mac OS X Cog Spur Squeak Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#

VMSRCDIR:= ../../spursrc/vm

APPPOST:=overwriteSqueakIcon

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app

# Replace the standard yellow VM icon with the green one used for Cog VMs

overwriteSqueakIcon: $(APP)/Contents/Resources/Squeak.icns
	cp -p $(OSXDIR)/GreenCogSqueak.icns $(APP)/Contents/Resources/Squeak.icns
