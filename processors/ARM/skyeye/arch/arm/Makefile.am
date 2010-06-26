arm_comm = common/arm_arch_interface.c common/armcopro.c common/armemu.c common/arminit.c common/armio.c common/armmem.c common/armmmu.c common/armos.c common/armsupp.c common/armvirt.c common/thumbemu.c 
arm_mmu = common/mmu/arm7100_mmu.c common/mmu/arm920t_mmu.c common/mmu/arm926ejs_mmu.c common/mmu/cache.c common/mmu/maverick.c common/mmu/rb.c common/mmu/sa_mmu.c common/mmu/tlb.c common/mmu/wb.c common/mmu/xscale_copro.c
arm_dbct = dbct/arm2x86.c dbct/arm2x86_coproc.c dbct/arm2x86_dp.c dbct/arm2x86_mem.c dbct/arm2x86_movl.c dbct/arm2x86_mul.c dbct/arm2x86_other.c dbct/arm2x86_psr.c dbct/arm2x86_shift.c dbct/arm2x86_test.c dbct/tb.c 
arm_mach =   mach/skyeye_mach_ep9312.c    mach/skyeye_mach_s3c2440.c\
mach/skyeye_mach_at91.c      mach/skyeye_mach_ns9750.c    mach/skyeye_mach_s3c3410x.c \
mach/skyeye_mach_ps7500.c     \
mach/skyeye_mach_at91rm92.c  mach/skyeye_mach_lh79520.c     mach/skyeye_mach_pxa250.c    mach/skyeye_mach_s3c4510b.c \
mach/skyeye_mach_cs89712.c   mach/skyeye_mach_lpc2210.c     mach/skyeye_mach_pxa270.c    mach/skyeye_mach_sa.c	 \
mach/skyeye_mach_ep7312.c    mach/skyeye_mach_lpc.c         mach/skyeye_mach_s3c2410x.c  mach/skyeye_mach_sharp.c mach/skyeye_mach_omap5912.c
libarm_a_SOURCES = $(arm_comm) $(arm_mmu) $(arm_mach)
if DBCT
libarm_a_SOURCES += $(arm_dbct)
endif
noinst_LIBRARIES =      libarm.a
DEFS = -DMODET -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 
libarm_a_LIBADD = armemu32.o
INCLUDES = -I$(top_srcdir)/utils/share -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/utils/profile -I$(top_srcdir)/arch/arm/common -I$(top_srcdir)/arch/arm/mach -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/device/uart -I$(top_srcdir)/device/flash @COMMON_INCLUDES@
armemu32.o:common/armemu.c
	$(CC) -DMODE32 $(DEFS) $(INCLUDES) common/armemu.c -c -o $@
