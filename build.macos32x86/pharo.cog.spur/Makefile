##############################################################################
# Makefile for Mac OS X Cog Spur Squeak Cocoa VM using clang and gnu make 3.81
# Do make init to allow make -n to function.
#
# Base definitions:
#
# VMSRCDIR defines the locaton of the VM source to build
#
# PLUGINSRCDIR defines the locaton of the plugin source, the subsets of which
# selected by plugins.int and plugins.ext will be build.
#
# CONFIGURATION defines what version of the VM to build, product, assert or debug
# The default is overridden in the mvm script
#
# COGDEFS supply any command-line defines to use, and may be null.
CONFIGURATION=product

VMSRCDIR:= ../../spursrc/vm
VM:=Pharo

# Now include the Makefile proper, which is common to all Mac OS builds.
#
include ../common/Makefile.app
