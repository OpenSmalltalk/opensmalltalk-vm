ppc_mach = mach/skyeye_mach_mpc8560.c
ppc_comm = common/ppc_alu.c common/ppc_cpu.c common/ppc_exc.c  common/ppc_mmu.c    common/ppc_vec.c \
common/ppc_arch_interface.c  common/ppc_dec.c       common/ppc_fpu.c  common/ppc_opc.c \
common/ppc_boot.c            common/ppc_e500_exc.c  common/ppc_io.c   common/ppc_tools.c
libppc_a_SOURCES = $(ppc_mach) $(ppc_comm)
noinst_LIBRARIES =      libppc.a
INCLUDES = -I./common -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/device/uart @COMMON_INCLUDES@
