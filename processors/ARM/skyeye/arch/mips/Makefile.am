mips_mach = mach/skyeye_mach_au1100.c  mach/skyeye_mach_nedved.c mach/skyeye_mach_fulong.c mach/skyeye_mach_gs32eb1.c
mips_comm = common/cache.c   common/decoder.c    common/icache.c common/mipsio.c    common/tlb.c \
common/cp0.c     common/emul.c       common/interrupt.c            common/mipsmem.c \
common/dcache.c  common/exception.c  common/mips_arch_interface.c  common/multiply.c
libmips_a_SOURCES = $(mips_mach) $(mips_comm)
noinst_LIBRARIES =      libmips.a
DEFS = -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 
INCLUDES = -I./common -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/device/uart @COMMON_INCLUDES@
