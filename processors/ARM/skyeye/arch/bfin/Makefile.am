bfin_mach = mach/bf533_io.c  mach/bf537_io.c
bfin_comm = common/bfin_arch_interface.c  common/bfin-dis.c  common/iomem.c
libbfin_a_SOURCES = $(bfin_mach) $(bfin_comm)
noinst_LIBRARIES =      libbfin.a
INCLUDES = -I./common -I./mach -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/device/uart @COMMON_INCLUDES@
