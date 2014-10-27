OBJS = $(BITBLT_OBJS)
XCFLAGS		= $(BITBLT_FLAGS)
ASMINCLUDES = -I$(topdir)/platforms/Cross/plugins/BitBltPlugin
ASMFLAGS = -cpu=$(ARM_ARCH)
AS = $(blddir)/../../asasm $(ASMFLAGS) $(ASMINCLUDES) -o