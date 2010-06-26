cf_mach = mach/skyeye_mach_mcf5249.c  mach/skyeye_mach_mcf5272.c
cf_comm = common/addressing.c  common/cf_arch_interface.c  common/exception.c  common/i.c       common/ram.c common/board.c       common/cycle.c              common/handlers.c   common/memory.c  
cf_insn = instruction/i_adda.c  instruction/i_dc.c       instruction/i_movem.c   instruction/i_scc.c \
instruction/i_add.c   instruction/i_div.c      instruction/i_moveq.c   instruction/i_stop.c \
instruction/i_addi.c  instruction/i_eor.c      instruction/i_movexr.c  instruction/i_suba.c \
instruction/i_addq.c  instruction/i_eori.c     instruction/i_mulu_l.c  instruction/i_sub.c \
instruction/i_addx.c  instruction/i_ext.c      instruction/i_mulu_w.c  instruction/i_subi.c \
instruction/i_and.c   instruction/i_halt.c     instruction/i_neg.c     instruction/i_subq.c \
instruction/i_andi.c  instruction/i_illegal.c  instruction/i_negx.c    instruction/i_subx.c \
instruction/i_asx.c   instruction/i_jmp.c      instruction/i_nop.c     instruction/i_swap.c \
instruction/i_bcc.c   instruction/i_jsr.c      instruction/i_not.c     instruction/i_trap.c \
instruction/i_btst.c  instruction/i_lea.c      instruction/i_or.c      instruction/i_trapf.c \
instruction/i_clr.c   instruction/i_link.c     instruction/i_ori.c     instruction/i_tst.c \
instruction/i_cmpa.c  instruction/i_lsx.c      instruction/i_pea.c     instruction/i_unlk.c \
instruction/i_cmp.c   instruction/i_move.c     instruction/i_rte.c \
instruction/i_cmpi.c  instruction/i_movec.c    instruction/i_rts.c
libcoldfire_a_SOURCES = $(cf_mach) $(cf_comm) $(cf_insn)

noinst_LIBRARIES =      libcoldfire.a
DEFS = -g -O2 -D_FILE_OFFSET_BITS=64 -DSTANDALONE -DDEFAULT_INLINE=0 

INCLUDES = -I./common -I$(top_srcdir)/utils/debugger -I$(top_srcdir)/device/uart @COMMON_INCLUDES@
