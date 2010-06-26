
SUBDIRS = arch/arm/ arch/bfin arch/coldfire arch/mips arch/ppc/ device/ utils/ memory/

#AM_LDFLAGS = $(LIBLS) --start-group $(top_srcdir)/arch/arm/libarm.a $(top_srcdir)/arch/bfin/libbfin.a $(top_srcdir)/arch/coldfire/libcoldfire.a $(top_srcdir)/arch/mips/libmips.a $(top_srcdir)/arch/ppc/libppc.a $(top_srcdir)/device/libdev.a $(top_srcdir)/utils/libutils.a --end-group
#AM_LDFLAGS = $(LIBLS) -L$(top_srcdir)/arch/arm/ -L$(top_srcdir)/arch/bfin/ -L$(top_srcdir)/arch/coldfire/ -L$(top_srcdir)/arch/mips/ -L$(top_srcdir)/device/ -L$(top_srcdir)/utils/ --start-group  -larm -lbfin -lcoldfire  -lmips -L$(top_srcdir)/arch/ppc/ -lppc -ldev -lutils --end-group

skyeye_LDADD = $(top_srcdir)/utils/libutils.a $(top_srcdir)/arch/arm/libarm.a $(top_srcdir)/device/libdev.a $(top_srcdir)/arch/mips/libmips.a $(top_srcdir)/arch/ppc/libppc.a $(top_srcdir)/arch/bfin/libbfin.a $(top_srcdir)/arch/mips/libmips.a $(top_srcdir)/arch/coldfire/libcoldfire.a $(top_srcdir)/memory/libmemory.a

# workaround getopt issue on Cygwin platform
skyeye_LDADD += -lc

# some functions in "libutils.a" which is required by other libs
skyeye_LDADD += $(top_srcdir)/utils/libutils.a

skyeye_LDFLAGS =

INCLUDES = @COMMON_INCLUDES@ -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/arch/arm/common -I$(top_srcdir)/arch/arm -I$(top_srcdir)/device/uart -I$(top_srcdir)/device -I$(top_srcdir)/utils/profile
DEFS = -DMODET -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 
bin_PROGRAMS = skyeye
skyeye_SOURCES = utils/main/skyeye.c

if LCD
skyeye_LDADD += @LCD_LIBS@
endif
