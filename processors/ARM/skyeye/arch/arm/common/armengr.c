/*  armengr.c -- Main instruction emulation:  SA11x Instruction Emulator.
    Copyright (C) 1994 Advanced RISC Machines Ltd.
    Modifications to add arch. v4 support by <jsmith@cygnus.com>.
 
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
 
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

#include "armdefs.h"
#include "armemu.h"
#include "armsym.h"

/***************************************************************************\
*                             ARM Energy                                    *
\***************************************************************************/

/* Instruction current in mA */
static long long instr_current[256] = {
	180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180,
		180,
	180,
	180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180,
		180,
	180,
	180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180,
		180,
	180,
	180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180,
		180,
	180,
	200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
		200,
	200,
	200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
		200,
	200,
	200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
		200,
	200,
	200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
		200,
	200,
	230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230,
		230,
	230,
	230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230, 230,
		230,
	230,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170,
	170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170, 170,
		170,
	170
};

//#define CLK_FREQ 206.0
//#define VDD 1.5
//static float mutilplier = 0;
//#define INSTR_ENERGY(i) instr_current[i]*VDD/CLK_FREQ /* in nJ per cycle */
//#define INSTR_ENERGY(i) instr_current[i]*mutilplier

// BUG200202071648: more accurate energy accounting
#define MEM_ENERGY 400		// tried to calculate for 4.7nJ
#define MEM_IDLE_ENERGY 40	// tried to calculate for 0.4nJ
#define IDLE_ENERGY 30
#define UART_ENERGY 40

/*added by ksh in 2004-09-03,according to PXA250 Developer Manual*/
/*********************************************
The following is the bitmap of CCCR,you can find it on the manual
[31:10] reserved
[9:7]   N
[6:5]   M
[4:0]   L


*************************************************/
float
Calculate_Mutilplier (ARMul_State * state)
{
	float Crystal_freq = 3.6864;
	int L, M;
	float N;
	float Core_freq;
	float Vdd;
	unsigned int cccr = state->energy.cccr;
//      printf("before calculate:cccr=0x%x,cccr&0x0=0x%x \n",cccr,cccr&0x0);
	switch ((cccr >> 7) & 0x7) {
	case 2:
		N = 1;
		break;
	case 3:
		N = 1.5;
		break;
	case 4:
		N = 2;
		break;
	case 6:
		N = 3;
		break;
	default:
		printf ("N is wrong\n ");
		N = 1;
		break;
	}
//printf("before calculate:cccr=0x%x,cccr&0x0=0x%x \n",cccr,cccr&0x0);
	switch ((cccr >> 5) & 0x3) {
	case 1:
		M = 1;
		break;
	case 2:
		M = 2;
		break;
	default:
		printf ("M is wrong\n");
		M = 1;
		break;
	}

	switch (cccr & 0x1f) {
	case 1:
		L = 27;
		break;
	case 2:
		L = 32;
		break;
	case 3:
		L = 36;
		break;
	case 4:
		L = 40;
		break;
	case 5:
		L = 45;
		break;
	default:
		printf ("L is wrong!\n");
		L = 1;
		break;
	}
	Core_freq = L * M * N * Crystal_freq;
//      printf("L=%d,M=%d,N=%llf,Core_freq=%f",L,M,N,Core_freq);
	if (Core_freq < 100) {
		Vdd = 0.85;
	}
	else if (100 < Core_freq < 200) {
		Vdd = 1.0;
	}
	else if (200 < Core_freq < 300) {
		Vdd = 1.1;
	}
	else if (300 < Core_freq < 400) {
		Vdd = 1.3;
	}
	else {
		printf ("Core_freq is %f,exceed!\n", Core_freq);
		skyeye_exit (-1);
	}

	//printf("cccr=0x%x,L=%d,M=%d,N=%d,Vdd = %d,Core_freq=%d,cccr>>7&0x7=0x%x,cccr>>7=0x%x,cccr&0x380=0x%x,cccr&0x0=0x%x,cccr&0x1f=0x%x\n",cccr,L,M,N,Vdd,Core_freq,(cccr>>7)&0x7,cccr>>7,cccr&0x380,cccr&0x0,cccr&0x1f);
	//printf("before calculate 5:cccr=0x%x,cccr&0x380=0x%x,cccr&0x0=0x%x \n",cccr,cccr&0x380,cccr&0x0);
//      printf("Vdd=%f,Core_freq=%f\n",Vdd,Core_freq);
	return Vdd / Core_freq;

}

/*get Vdd,added by ksh in 2004-09-03*/
float
get_Vdd (float Core_freq)
{
	if (Core_freq < 100) {
		return 0.85;
	}
	if (Core_freq < 200) {
		return 1.0;
	}
	if (Core_freq < 300) {
		return 1.1;
	}
	if (Core_freq < 400) {
		return 1.3;
	}
	else {
		return 0.0;
	}

}

static long long pf_p_cyc, pf_p_energy;
static int check_point = 0;

void
ARMul_EnergyInit (ARMul_State * state)
{
	printf ("call ARMul_EnergyInit() \n");
	state->energy.t_energy = 0;
	state->energy.tcycle = 0;
	state->energy.pcycle = 0;
	state->energy.t_mem_cycle = 0;
	state->energy.t_idle_cycle = 0;
	state->energy.t_uart_cycle = 0;
	state->energy.p_mem_cycle = 0;
	state->energy.p_idle_cycle = 0;
	state->energy.p_uart_cycle = 0;
	state->energy.p_io_update_tcycle = 0;

	pf_p_cyc = 0;
	pf_p_energy = 0;

	check_point = 1;
	return;
}

void
ARMul_do_energy (ARMul_State * state, ARMword instr, ARMword pc)
{
	int opcode;
	long long ex_cycle, timing_cycle;
	long long mem_cycle, idle_cycle, uart_cycle, mem_idle_cycle;
	float ex_energy;
	float mem_energy, idle_energy, uart_energy, mem_idle_energy;
	float cur_cyc_energy;
	TASK_STACK *tsp;

	if (!state->energy.energy_prof) {
		return;
	}
	if (check_point == 0) {
		printf ("failed check point\n");
		skyeye_exit (-1);
	}

	if (state->energy.energy_prof) {	// BUG200103282109 
		state->energy.tcycle =
			state->NumScycles + state->NumNcycles +
			state->NumIcycles;
		ex_cycle = state->energy.tcycle - state->energy.pcycle;
		mem_cycle =
			state->energy.t_mem_cycle - state->energy.p_mem_cycle;
		idle_cycle =
			state->energy.t_idle_cycle -
			state->energy.p_idle_cycle;
		uart_cycle =
			state->energy.t_uart_cycle -
			state->energy.p_uart_cycle;
		mem_idle_cycle = ex_cycle - mem_cycle;

		state->energy.pcycle = state->energy.tcycle;
		state->energy.p_mem_cycle = state->energy.t_mem_cycle;
		state->energy.p_idle_cycle = state->energy.t_idle_cycle;
		state->energy.p_uart_cycle = state->energy.t_uart_cycle;

		opcode = BITS (20, 27);
		/*added by ksh for calculate freq and vdd */
		ex_energy = instr_current[opcode] * ex_cycle * Calculate_Mutilplier (state);	/* <tktan> BUG200105232215 */
		mem_energy = mem_cycle * MEM_ENERGY;
		idle_energy = idle_cycle * IDLE_ENERGY;
		uart_energy = uart_cycle * UART_ENERGY;
		mem_idle_energy = mem_idle_cycle * MEM_IDLE_ENERGY;

		cur_cyc_energy =
			ex_energy + mem_energy + idle_energy + uart_energy +
			mem_idle_energy;
		state->energy.t_energy += cur_cyc_energy;

		/*task energy profiling */
		tsp = (TASK_STACK *) state->energy.cur_task;
		tsp->total_cycle += ex_cycle;
		tsp->total_energy += cur_cyc_energy;

		if (state->NextInstr >= PRIMEPIPE) {
			ARMul_CallCheck (state, pc, state->Reg[15], instr);	/* BUG200104012116 */
		}
	}			//add by chy 2004-11-27 bug??
	return;
}

/* 
void ARMul_do_cycle(ARMul_State *state)
{
  do {
    io_do_cycle(state);
  } while (state->mmu.mode != RUN_MODE) ;
}*/
