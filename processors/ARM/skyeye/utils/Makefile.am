utils_config = config/skyeye_arch.c  config/skyeye_config.c  config/skyeye_options.c
utils_debugger = debugger/arch_regdefs.c  debugger/cf_regdefs.c      debugger/mips_regdefs.c \
debugger/arm_regdefs.c   debugger/gdbserver.c       debugger/ppc_regdefs.c  \
debugger/bfin_regdefs.c  debugger/gdb_tracepoint.c  debugger/skyeye2gdb.c

utils_profile = profile/code_cov.c profile/symbol.c

utils_portable = portable/mman.c portable/usleep.c portable/gettimeofday.c

libutils_a_SOURCES = $(utils_config) $(utils_debugger) $(utils_profile) $(utils_portable)
noinst_LIBRARIES =      libutils.a
DEFS = -DMODET -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 

INCLUDES =  -I$(top_srcdir)/arch/arm/dbct -I$(top_srcdir)/device/uart -I$(top_srcdir)/device/net -I$(top_srcdir)/device/lcd -I$(top_srcdir)/arch/arm/common -I$(top_srcdir)/arch/arm -I$(top_srcdir)/arch/bfin/common -I$(top_srcdir)/arch/mips/common -I$(top_srcdir)/arch/ppc/common @COMMON_INCLUDES@

if LCD
INCLUDES += @LCD_CFLAGS@
endif 

