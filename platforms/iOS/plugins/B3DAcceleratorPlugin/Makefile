# The current version of B3DAcceleratorPlugin (the OpenGL interface) uses
# FindWindow, GetWindowGreatestAreaDevice & GetWindowPort which are Carbon &
# 32-bit only.  So include the Carbon frameworks.  Until this can be rewritten
# this implies no 64-bit OpenGL on Mac OS X :-(.

INCDIRS:=../../platforms/Cross/plugins/FilePlugin \
         ../../platforms/unix/vm
INCDIRS:=../../platforms/unix/vm


# These three are imported from the VM.  Use this explicit list instead of
# -undefined dynamic_lookup to get errors for any other missing imports.
EXTRABFLAGS=-Wl,-U,_imageName,-U,_getSTWindow,-U,_setPostMessageHook
EXTRADYFLAGS=-Wl,-U,_imageName,-U,_getSTWindow,-U,_setPostMessageHook
EXTRALIBS:= -framework CoreFoundation -framework Carbon -framework OpenGL -framework AGL

include ../common/Makefile.plugin
