# The current version of B3DAcceleratorPlugin (the OpenGL interface) uses lots
# of Carbon code & is hence 32-bit only.  So include the Carbon frameworks.
# Until this can be rewritten this implies no 64-bit OpenGL on Mac OS X :-(.

INCDIRS:=../../platforms/Cross/plugins/FilePlugin \
         ../../platforms/unix/vm
INCDIRS:=../../platforms/unix/vm


EXTRALIBS:= -framework CoreFoundation -framework Carbon -framework OpenGL -framework AGL
#EXTRALIBS:= -framework OpenGL -framework AGL

include ../common/Makefile.plugin
