# make.prg.in -- mf fragment for programs		-*- makefile -*-
# 
# Author: Ian.Piumarta@inria.fr, eliot, topa
# 

o		= .o
a		= .a
x		=
COMPILE		= $(CC) $(CFLAGS) $(CPPFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -c -o
COMPILEIFP	= $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -fno-omit-frame-pointer -c -o
CXXFLAGS	= $(CFLAGS) # Hack; can't be bothered to add CXXFLAGS to the configure mess
COMPILE.cpp = $(COMPILE.cc)
COMPILE.cc	= $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -c -o
LINK		= $(LIBTOOL) --mode=link \
		  $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) $(TARGET_ARCH) -export-dynamic -shared -o
RANLIB		= :
