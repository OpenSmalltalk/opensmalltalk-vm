# make.prg.in -- mf fragment for programs		-*- makefile -*-
# 
# Author: Ian.Piumarta@inria.fr
# 
# Last edited: 2002-12-01 09:28:43 by piumarta on calvin.inria.fr

o		= .o
a		= .a
x		=
COMPILE		= $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) -export-dynamic -c -o
LINK		= $(LIBTOOL) --mode=link \
		  $(CC) $(CFLAGS) $(XCFLAGS) \
		  $(LDFLAGS) $(XLDFLAGS) -export-dynamic -R$(libdir) -o
RANLIB		= :
