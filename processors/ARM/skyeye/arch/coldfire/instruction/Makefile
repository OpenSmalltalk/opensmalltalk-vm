CROSS_COMPILE ?=
EXTRA_CFLAGS ?=

CC	= $(CROSS_COMPILE)gcc
CFLAGS	= -Wall -fomit-frame-pointer -g -O2 -I../common -I../tracer $(EXTRA_CFLAGS)

LD_R	= $(CROSS_COMPILE)ld -r
RM	= rm -f
LDFLAGS = 

BUILD		= i.o
C_SRCS		= i_add.c i_adda.c i_addi.c i_addq.c i_addx.c i_and.c \
		  i_andi.c i_asx.c i_bcc.c i_btst.c i_clr.c i_cmp.c \
		  i_cmpa.c i_cmpi.c i_dc.c i_eor.c i_eori.c i_ext.c \
		  i_halt.c i_illegal.c i_jmp.c i_jsr.c i_lea.c \
		  i_link.c i_lsx.c i_move.c i_movec.c i_movem.c \
		  i_moveq.c i_movexr.c i_mulu_l.c i_mulu_w.c \
		  i_neg.c i_negx.c i_nop.c i_not.c i_or.c \
		  i_ori.c i_pea.c i_rte.c i_rts.c i_scc.c i_stop.c \
		  i_sub.c i_suba.c i_subi.c i_subq.c i_subx.c \
		  i_swap.c i_trap.c i_trapf.c i_tst.c i_unlk.c i_div.c

OBJS = $(C_SRCS:.c=.o)

all: $(BUILD)

.c.o:
	$(CC) $(CFLAGS) -c $<

clean:
	$(RM) $(OBJS) $(BUILD) 

$(BUILD): $(OBJS)
	$(LD_R) $(OBJS) -o $@
