#ifndef __BFIN_SIM_H_
#define __BFIN_SIM_H_

#include "types.h"
#include <stdio.h>

enum
{
	EMU_MODE = 1,
	SUPER_MODE,
	USR_MODE
};

#define MAXBANKS 5
typedef struct
{
	bu32 dpregs[16], iregs[4], mregs[4], bregs[4], lregs[4];
	bu64 a0, a1;
	bu32 lt[2], lc[2], lb[2];
	int ac0, ac0_copy, ac1, an, aq;
	int av0, av0s, av1, av1s, az, cc, v, v_copy, vs;
	int v_internal;
	bu32 syscfg;
	bu32 usp, old_sp;
	bu32 pc, rets, reti, retx, retn, rete;
	int mode;
	bu32 astat, seqstat;

	bu32 oldpc;
	bu32 olderpc;
	unsigned char *insn_end;

	int ticks;
	int stalls;
	int memstalls;
	int cycles;
	int insts;

	int prevlock;
	int thislock;
	int exception;

	int end_of_registers;

	int msize;
#define PROFILE_FREQ 1
#define PROFILE_SHIFT 2
	unsigned short *profile_hist;
	unsigned char *memory;
	unsigned char *dsram;
	unsigned char *isram;
        unsigned char *ssram; //PSW 061606 added scratchpad 
//  struct mem_bank *bank;

	int xyram_select, xram_start, yram_start;
	unsigned char *xmem;
	unsigned char *ymem;
	unsigned char *xmem_offset;
	unsigned char *ymem_offset;
	unsigned int bfd_mach;
	//mach_t *p_mach;
	void (*sti)(bu32 * dreg);	
	void (*cli)(bu32 * dreg);
	void (*disable_int)();
	void (*enable_int)();
	void (*clear_int)(int);
	void (*set_int)(int);
} saved_state_type;

extern saved_state_type saved_state;

#define DREG(x) saved_state.dpregs[x]
#define DPREG(x) saved_state.dpregs[x]
#define GREG(x,i) DPREG ((x) | (i << 3))
#define PREG(x) saved_state.dpregs[x + 8]
#define SPREG 	(PREG(6))
#define FPREG 	(PREG(7))
#define USPREG saved_state.usp
#define RETIREG saved_state.reti
#define IREG(x) saved_state.iregs[x]
#define LREG(x) saved_state.lregs[x]
#define MREG(x) saved_state.mregs[x]
#define BREG(x) saved_state.bregs[x]

#define A0REG   saved_state.a0
#define A0XREG ((bu32 *)(&saved_state.a0))[0]
#define A0WREG ((bu32 *)(&saved_state.a0))[1]
#define A1REG   saved_state.a1
#define A1XREG ((bu32 *)(&saved_state.a1))[0]
#define A1WREG ((bu32 *)(&saved_state.a1))[1]


#define CCREG saved_state.cc
#define PCREG saved_state.pc
#define LC0REG saved_state.lc[0]
#define LT0REG saved_state.lt[0]
#define LB0REG saved_state.lb[0]
#define LC1REG saved_state.lc[1]
#define LT1REG saved_state.lt[1]
#define LB1REG saved_state.lb[1]

#define RETSREG saved_state.rets
#define RETIREG saved_state.reti
#define RETNREG saved_state.retn
#define RETXREG saved_state.retx
#define RETEREG saved_state.rete

#define PCREG saved_state.pc
#define USPREG saved_state.usp
#define ASTATREG saved_state.astat
#define SEQSTATREG saved_state.seqstat

#define OLDPCREG saved_state.oldpc
#define OLDERPCREG saved_state.olderpc

#define OLDSPREG saved_state.old_sp
#define MODE saved_state.mode

#define AQFLAG saved_state.aq
#define AZFLAG saved_state.az
extern int did_jump;

typedef struct
{

} bfin_sim_info;
#endif
