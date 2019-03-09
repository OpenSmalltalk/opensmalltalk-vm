# The current version of B3DAcceleratorPlugin (the OpenGL interface) uses lots
# of Carbon code & is hence 32-bit only.  So include the Carbon frameworks.
# Until this can be rewritten this implies no 64-bit OpenGL on Mac OS X :-(.

INCDIRS:=$(PLATDIR)/Cross/plugins/FilePlugin \
         $(PLATDIR)/unix/vm
INCDIRS:=$(PLATDIR)/unix/vm

EXTRADYFLAGS=-Wl,-U,_getImageName,-U,_getSTWindow,-U,_setWindowChangedHook,-U,_warning
#EXTRALIBS:= -framework OpenGL -framework AGL

include ../common/Makefile.plugin

ifeq ($(TARGET_ARCH), i386)
EXTRADYFLAGS=-Wl,-U,_getMainWindowOpenGLContext,-U,_createOpenGLTextureLayerHandle,-U,_destroyOpenGLTextureLayerHandle,-U,_setOpenGLTextureLayerContent
EXTRALIBS:= -framework CoreFoundation -framework OpenGL -framework Cocoa
else
EXTRADYFLAGS=-Wl,-U,_getMainWindowMetalDevice,-U,_getMainWindowMetalCommandQueue,-U,_createMetalTextureLayerHandle,-U,_destroyMetalTextureLayerHandle,-U,_setMetalTextureLayerContent
EXTRALIBS:= -framework CoreFoundation -framework Metal -framework Cocoa
endif
