#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"
#include "sharp.h"
#define F_CORE (200 * 1024 * 1024)	//core frequence
#define F_OS    508469		//OS timer
#define OS_SCALE (F_CORE / F_OS / 10)

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"


typedef struct shp_io_t
{
	INTCREGS intc;
	TIMERREGS timer1;
	TIMERREGS timer2;
	UARTREGS uart2;

	u32 timer1_scale;
	u32 timer2_scale;
	u32 uart_scale;
} shp_io_t;

static shp_io_t shp_io;

static void refresh_irq (ARMul_State *);
static void
shp_io_reset ()
{
	memset (&shp_io, 0, sizeof (shp_io));

}

static void
shp_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	shp_ioregnum_t ioregaddr = addr;
	switch (ioregaddr) {
	case CPLDKEYSTATE:
		break;
	case CPLDINTSTATE:
		break;
	case CPLDINTMASK:
		break;
	case CPLDPWRIO:
		break;
	case CPLDEXTIO:
		break;

	default:
		printf ("SKYEYE: shp_io_write_byte %08x error, PC %x\n", addr,
			state->Reg[15]);
	}
	return;
}

static void
shp_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: shp_io_write_halfword error\n");
	skyeye_exit (-1);
}

static void
shp_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	shp_ioregnum_t ioregaddr = addr;

	switch (ioregaddr) {
		/* Interrupt controller */
	case INTSR:		//RO
		break;
	case INTRSR:		//RO
		break;
	case INTENS:
/* BUGBUG: Writing a bit as 1 in this register enables the corresponding interrupt source. Clearing a bit
    by writing a 0 in INTENS will not change that bit nor disable the interrupt. Use the INTENC
    register to disable interrupt sources.
 */
		shp_io.intc.enableset = data;
		break;
	case INTENC:		//WO
/* BUGBUG: Reading this register returns 0. Set a bit to 1 in this register to clear the corresponding bit in
    INTENS and disable the corresponding interrupt source. An attempt to clear a bit by writing
    a 0 in this register does not change INTENS.
 */
		shp_io.intc.enableclear = data;
		break;

		/* timer 1 */
	case TIMERLOAD1:
		shp_io.timer1.load = data & 0xffff;
		shp_io.timer1.value = shp_io.timer1.load;	//reset
		break;
	case TIMERVALUE1:	//RO
		break;
	case TIMERCONTROL1:
		shp_io.timer1.control = data & 0xc4;
		break;
	case TIMERTCEOI1:	//WO
		shp_io.timer1.clear = 0;
		break;

		/* timer 2 */
	case TIMERLOAD2:
		shp_io.timer2.load = data & 0xffff;
		shp_io.timer2.value = shp_io.timer2.load;	//reset
		break;
	case TIMERVALUE2:	//RO
		break;
	case TIMERCONTROL2:
		shp_io.timer2.control = data & 0xc4;
		break;
	case TIMERTCEOI2:	//WO
		shp_io.timer2.clear = 0;
		break;

		/*UART 2 */
	case UART2DATA:
		shp_io.uart2.data = data & 0xfff;
		{
			unsigned char c = shp_io.uart2.data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			shp_io.uart2.status &= ~UART_STATUS_TXFF;
		}
		break;
	case UART2FCON:
		shp_io.uart2.lcr = data & 0xff;
		break;
	case UART2BRCON:
		shp_io.uart2.bcr = data & 0xffff;
		break;
	case UART2CON:
		shp_io.uart2.control = data & 0xff;
		break;
	case UART2STATUS:	//RO
		break;
	case UART2RAWISR:	//WO
		shp_io.uart2.intraw = 0;
		break;
	case UART2INTEN:
		shp_io.uart2.inte = data & 0xf;
		break;
	case UART2ISR:		//RO
		break;

	default:
		printf ("SKYEYE: shp_io_write_word: unknown addr 0x%x, reg15 0x%x \n", addr, state->Reg[15]);
	}
}

static ARMword
shp_io_read_byte (ARMul_State * state, ARMword addr)
{
	u32 data = 0;
	shp_ioregnum_t ioregaddr = addr;
	switch (ioregaddr) {
	case CPLDKEYSTATE:
		break;
	case CPLDINTSTATE:
		break;
	case CPLDINTMASK:
		break;
	case CPLDPWRIO:
		break;
	case CPLDEXTIO:
		break;

	default:
		printf ("SKYEYE: shp_io_read_byte %08x error, PC %x\n", addr,
			state->Reg[15]);
	}
//  printf("SKYEYE: shp_io_read_byte error\n");
	return data;
}

static ARMword
shp_io_read_halfword (ARMul_State * state, ARMword addr)
{
	printf ("SKYEYE: shp_io_read_halfword error\n");
	skyeye_exit (-1);
}

static ARMword
shp_io_read_word (ARMul_State * state, ARMword addr)
{
	u32 data;
	shp_ioregnum_t ioregaddr = addr;

	switch (addr) {
		/* Interrupt controller */
	case INTSR:		//RO
		data = shp_io.intc.status;
		break;
	case INTRSR:		//RO
		data = shp_io.intc.rawstatus;
		break;
	case INTENS:
		data = shp_io.intc.enableset;
		break;
	case INTENC:		//WO
		break;

		/* timer 1 */
	case TIMERLOAD1:
		data = shp_io.timer1.load & 0xffff;
		break;
	case TIMERVALUE1:	//RO
		data = 0xffff;	//shp_io.timer1.value & 0xffff;
		break;
	case TIMERCONTROL1:
		data = shp_io.timer1.control & 0xc4;
		break;
	case TIMERTCEOI1:	//WO
		data = 0;
		break;

		/* timer 2 */
	case TIMERLOAD2:
		data = shp_io.timer2.load & 0xffff;
		break;
	case TIMERVALUE2:	//RO
		data = shp_io.timer2.value & 0xffff;
		break;
	case TIMERCONTROL2:
		data = shp_io.timer2.control & 0xc4;
		break;
	case TIMERTCEOI2:	//WO
		data = 0;
		break;

		/*UART 2 */
	case UART2DATA:
		data = shp_io.uart2.data & 0xfff;
		shp_io.uart2.status |= UART_STATUS_RXFE;
		break;
	case UART2FCON:
		data = shp_io.uart2.lcr & 0xff;
		break;
	case UART2BRCON:
		data = shp_io.uart2.bcr & 0xffff;
		break;
	case UART2CON:
		data = shp_io.uart2.control & 0xff;
		break;
	case UART2STATUS:
		data = shp_io.uart2.status & 0xff;
		break;
	case UART2RAWISR:	//WO
		data = shp_io.uart2.intraw & 0xf;
		break;
	case UART2INTEN:
		data = shp_io.uart2.inte & 0xf;
		break;
	case UART2ISR:
		data = shp_io.uart2.intr & 0xf;
		break;

	default:
		printf ("SKYEYE: shp_io_read_word: unknown addr 0x%x, reg15 0x%x \n", addr, state->Reg[15]);
	}

	return data;
}


static void
shp_io_do_cycle (ARMul_State * state)
{

	
	/*timer1 */
	if (++shp_io.timer1_scale >= 5000) {
		shp_io.timer1_scale = 0;
		if (shp_io.timer1.control & TIMER_CTRL_ENABLE) {
			if (shp_io.timer1.value-- == 0) {
				shp_io.timer1.clear = 1;	//note timer intrrupt
				if (shp_io.timer1.
				    control & TIMER_CTRL_PERIODIC)
					shp_io.timer1.value =
						shp_io.timer1.load;
				else
					shp_io.timer1.value = 0xffff;
			}
		}
	}

	/*timer2 */
	if (++shp_io.timer2_scale >= 5000) {
		shp_io.timer2_scale = 0;
		if (shp_io.timer2.control & TIMER_CTRL_ENABLE) {
			if (shp_io.timer2.value-- == 0) {
				shp_io.timer2.clear = 1;	//note timer intrrupt
				if (shp_io.timer2.
				    control & TIMER_CTRL_PERIODIC)
					shp_io.timer2.value =
						shp_io.timer2.load;
				else
					shp_io.timer2.value = 0xffff;
			}
		}
	}

	/*uart2 */
	if (++shp_io.uart_scale >= 512) {
		shp_io.uart_scale = 0;
		if (shp_io.uart2.control & UART_CONTROL_EN) {
			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			struct timeval tv;
			unsigned char c;

			tv.tv_sec = 0;
			tv.tv_usec = 0;

			if(skyeye_uart_read(-1, &c, 1, &tv, NULL) > 0)
			{
				shp_io.uart2.data = (int) c;
				shp_io.uart2.status &= ~UART_STATUS_RXFE;
			}
		}
	}


	/*reset interrupt pin status */
	refresh_irq (state);
};


static void
refresh_irq (ARMul_State * state)
{
	//BUGBUG: when update interrupt status?
	shp_io.intc.rawstatus = 0;

	/*timer1 */
	if (shp_io.timer1.clear) {
		shp_io.intc.rawstatus |= INTC_TC1OINTR;
	}

	/*timer2 */
	if (shp_io.timer2.clear) {
		shp_io.intc.rawstatus |= INTC_TC2OINTR;
	}

	shp_io.intc.status = shp_io.intc.rawstatus & shp_io.intc.enableset;

	state->NirqSig = shp_io.intc.status ? LOW : HIGH;
}

void
shp_mach_init (ARMul_State * state, machine_config_t * mc)
{
	ARMul_SelectProcessor (state,
			       ARM_XScale_Prop | ARM_v5_Prop | ARM_v5e_Prop);
	state->lateabtSig = LOW;

	state->Reg[1] = 89;	/*BUGBUG: lubbock machine id. */

	shp_io_reset ();
	mc->mach_io_do_cycle = shp_io_do_cycle;
	mc->mach_io_reset = shp_io_reset;
	mc->mach_io_read_byte = shp_io_read_byte;
	mc->mach_io_write_byte = shp_io_write_byte;
	mc->mach_io_read_halfword = shp_io_read_halfword;
	mc->mach_io_write_halfword = shp_io_write_halfword;
	mc->mach_io_read_word = shp_io_read_word;
	mc->mach_io_write_word = shp_io_write_word;
}
