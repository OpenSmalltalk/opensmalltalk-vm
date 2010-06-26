/*
        skyeye_mach_mpc8560.c - mpc8560 machine simulation implementation
        Copyright (C) 2003-2007 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 01/04/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include <stdint.h>
#include "skyeye_config.h"

#include <ppc_cpu.h>

typedef struct mpc8560_uart_s{
}mpc8560_uart_t;
#if 0
typedef struct pic_global_s{
	uint32_t brr[2];
	uint32_t ipidr[4];
	uint32_t ctpr;
	uint32_t whoami;
	uint32_t iask;
	uint32_t eoi;
	uint32_t frr;
	uint32_t gcr;
	uint32_t vir;
	uint32_t pir;
	uint32_t ipivpr[4];
	uint32_t svr;
}pic_global_t;
#endif
typedef struct global_timer_s{
	uint32_t gtccr;
	uint32_t gtbcr;
	uint32_t gtvpr;
	uint32_t gtdr;
}global_timer_t;
typedef struct pic_timer_s{
	uint32_t tfrr;
	global_timer_t timer[4];
	uint32_t tcr;
}pic_timer_t;
typedef struct pic_int_summary_s{
	uint32_t erqsr;
	uint32_t irqsr[3];
	uint32_t cisr[3];
}pic_int_summary_t;
/* Performance Monitor Mask Registers */
typedef struct pic_pmm_s{
	uint32_t pm0mr[3];
	uint32_t pm1mr[3];
	uint32_t pm2mr[3];
	uint32_t pm3mr[3];
}pic_pmm_t;
/* Message Register */
typedef struct pic_message_s{
	uint32_t msgr[4];
	uint32_t mer;
	uint32_t msr;
	uint32_t msir[8];
	uint32_t msisr;
	uint32_t msiir;
}pic_message_t;
/* Interrupt source configuration register */
typedef struct pic_isc_s{
	uint32_t eivpr[12];
	uint32_t eidr[12];
	uint32_t iivpr[48];
	uint32_t iidr[48];
	uint32_t mivpr[4];
	uint32_t midr[4];
	uint32_t msivpr[8];
	uint32_t msidr[8];
}pic_isc_t;
/*
typedef struct pic_percpu_s{
	uint32_t ipidr[4];
	uint32_t ctpr;
	uint32_t whoami;
	uint32_t iask;
	uint32_t eoi;
}pic_percpu_t;
*/
typedef struct mpc8560_pic_s{
	global_timer_t timer_reg;	
	//pic_global_t global_reg;
	pic_pmm_t pmm_reg;
	pic_message_t message_reg;
	pic_isc_t isc_reg;
	pic_percpu_t percpu_reg;
}mpc8560_pic_t;
/* local address register window defined by mpc8560 */
typedef struct mpc8560_law_s{
	uint32_t lawbar[8];
	uint32_t lawar[8];
}mpc8560_law_t;

/* local configuration register */
typedef struct mpc8560_conf_s{
	uint32_t ccsrbar; /* Configuration,control, and status registers base address register */
	uint32_t altcbar; /* alternate configuration base address register */
	uint32_t altcar; /* alternate configuration attribute register */
	uint32_t bptr; /* boot page translation register */
}mpc8560_conf_t;

typedef struct mpc8560_io_s{
	mpc8560_pic_t pic;
	mpc8560_law_t law;
	mpc8560_conf_t conf;
}mpc8560_io_t;
static mpc8560_io_t mpc8560_io;

static void
mpc8560_io_do_cycle (void * state)
{
}
static void
mpc8560_io_reset (void * state)
{
}
static uint32_t
mpc8560_io_read_byte (void * state, uint32_t addr){}
static uint32_t
mpc8560_io_read_halfword (void * state, uint32_t addr){}
static uint32_t
mpc8560_io_read_word (void * state, uint32_t addr)
{}
static void
mpc8560_io_write_byte (void * state, uint32_t addr, uint32_t data)
{
}
static void
mpc8560_io_write_halfword (void * state, uint32_t addr, uint32_t data)
{
}
static void
mpc8560_io_write_word (void * state, uint32_t addr, uint32_t data)
{}
static void
mpc8560_update_int (void * state)
{
}
void mpc8560_mach_init( void * state, machine_config_t * this_mach){
	PPC_CPU_State * p_state = (PPC_CPU_State *)state;	

	this_mach->mach_io_do_cycle = mpc8560_io_do_cycle;
        this_mach->mach_io_reset = mpc8560_io_reset;
        this_mach->mach_io_read_byte = mpc8560_io_read_byte;
        this_mach->mach_io_write_byte = mpc8560_io_write_byte;
        this_mach->mach_io_read_halfword = mpc8560_io_read_halfword;
        this_mach->mach_io_write_halfword = mpc8560_io_write_halfword;
        this_mach->mach_io_read_word = mpc8560_io_read_word;
        this_mach->mach_io_write_word = mpc8560_io_write_word;
        this_mach->mach_update_int = mpc8560_update_int;
	//mpc8560_io.conf.ccsrbar = 0x000FF700;
	/* Just for convience of boot linux */
	mpc8560_io.conf.ccsrbar = 0x000E0000;

	/* initialize interrupt controller */
	int i = 0;
	for(; i < 32; i++){
		p_state->pic_ram.iidr[i] = 0x1;
		p_state->pic_ram.iivpr[i] = 0x80800000;
	}	
}
