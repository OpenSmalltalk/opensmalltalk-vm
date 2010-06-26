/*
        skyeye_mach_integrator.c - integrator machine simulation 
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
 * 03/02/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "armdefs.h"
typedef struct integrator_timer_s{
	uint32_t timer_load;
	uint32_t timer_value;
	uint32_t timer_control;
	uint32_t timer_intclr;
	uint32_t timer_ris;
	uint32_t timer_mis;
	uint32_t timer_bgload;
}integrator_timer_t;
typedef struct uart_s{
	uint32_t uartdr;
	uint32_t uartrsr;
	uint32_t uartfr;
	uint32_t uartilpr;
	uint32_t uartibrd;
	uint32_t uartfbrd;
	uint32_t uartlcr_h;
	uint32_t uartcr;
	uint32_t uartifls;
	uint32_t uartimsc;
	uint32_t uartris;
	uint32_t uartmis;
	uint32_t uarticr;
	uint32_t uartdmacr;
	uint32_t uartperiphID[4];
	uint32_t uartpcellID[4];
}uart_t;
typedef struct pic_s{
	uint32_t irq_status;
	uint32_t irq_rawstatus;
	uint32_t irq_enableset;
	uint32_t irq_enableclr;
	uint32_t int_softset;
	uint32_t int_softclr;
	uint32_t fiq_status;
	uint32_t fiq_rawstat;
	uint32_t fiq_enableset;
	uint32_t fiq_enableclr;
}pic_t;
typedef struct integrator_io_s{
	integrator_timer_t timer[3];
	uart_t uart[2];
	pic_t pic;
}integrator_io_t;
void integrator_io_do_cycle(){}

ARMword
integrator_io_read_word (void * state, ARMword addr)
{
	/*
	 *       * The LPC system registers
	 *               */

	ARMword data = -1;
	static ARMword current_ivr = 0;	/* mega hack,  2.0 needs this */
	int i;
	ARMword dataimr = 0;

	return data;
}

ARMword
integrator_io_read_byte (void * state, ARMword addr)
{
	return integrator_io_read_word (state, addr);
//                      SKYEYE_OUTREGS(stderr);
	//exit(-1);

}

ARMword
integrator_io_read_halfword (void * state, ARMword addr)
{
	return integrator_io_read_word (state, addr);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}


void
integrator_io_write_word (void * state, ARMword addr, ARMword data)
{
	/*
	 * The integrator system registers
	 */


}

void
integrator_io_write_byte (void * state, ARMword addr, ARMword data)
{

	integrator_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);

}

void
integrator_io_write_halfword (void * state, ARMword addr, ARMword data)
{
	integrator_io_write_word (state, addr, data);
	//SKYEYE_OUTREGS(stderr);
	//exit(-1);
}
static void
integrator_io_reset (void * curr_state)
{
}


void
integrator_mach_init (ARMul_State * state, machine_config_t * this_mach)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = HIGH;

	state->Reg[1] = 21; /* MACH_TYPE_INTEGRATOR defined in linux source */

	this_mach->mach_io_do_cycle = integrator_io_do_cycle;
	this_mach->mach_io_reset = integrator_io_reset;
	this_mach->mach_io_read_byte = integrator_io_read_byte;
	this_mach->mach_io_write_byte = integrator_io_write_byte;
	this_mach->mach_io_read_halfword = integrator_io_read_halfword;
	this_mach->mach_io_write_halfword = integrator_io_write_halfword;
	this_mach->mach_io_read_word = integrator_io_read_word;
	this_mach->mach_io_write_word = integrator_io_write_word;

	//this_mach->mach_update_int = integrator_update_int;

}
