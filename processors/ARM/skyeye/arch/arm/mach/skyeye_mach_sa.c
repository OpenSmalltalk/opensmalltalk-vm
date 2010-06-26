#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "armdefs.h"

#include "sa1100.h"
#define F_CORE (100 * 1024 * 1024)	//core frequence
#define F_RTC 32768		//RTC
#define F_OS	3686400		//OS timer
#define RT_SCALE (F_CORE / F_RTC)
#define OS_SCALE (F_CORE / F_OS / 10)
#define UART3_SCALE	200

/* 2007-01-18 added by Anthony Lee : for new uart device frame */
#include "skyeye_uart.h"


typedef struct sa_io_t
{
	/*interrupt controller */
	u32 icpr;
	u32 icip;
	u32 icfp;
	u32 icmr;
	u32 iccr;
	u32 iclr;

	/*real time clock(RTC) */
	u32 rcnr;
	u32 rtar;
	u32 rtsr;
	u32 rttr;

	u32 rt_scale;		/*core frequence to 32.768K */
	u32 rt_count;

	/*os timer */
	u32 oscr;
	u32 osmr0, osmr1, osmr2, osmr3;
	u32 ower;
	u32 ossr;
	u32 oier;

	u32 os_scale;

	/*uart3 controller */
	u32 utcr0;
	u32 utcr1;
	u32 utcr2;
	u32 utcr3;
	u32 utdr;
	u32 utsr0;
	u32 utsr1;

	u32 uart3_scale;

	/* 2007-01-21 added by Anthony Lee */
	u8 uart3_buf;
} sa_io_t;

static sa_io_t sa_io;

static void refresh_irq (ARMul_State *);
static void
sa_io_reset ()
{
	memset (&sa_io, 0, sizeof (sa_io));

	sa_io.utsr0 = 1;	/*always TFS, no others */
	sa_io.utsr1 = 0x4;
 /*TNF*/};
void
sa_io_write_byte (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: sa_io_write_byte error\n");
	skyeye_exit (-1);
}

void
sa_io_write_halfword (ARMul_State * state, ARMword addr, ARMword data)
{
	printf ("SKYEYE: sa_io_write_halfword error\n");
	skyeye_exit (-1);
}

static void
sa_io_write_word (ARMul_State * state, ARMword addr, ARMword data)
{
	switch (addr) {
	 /*RTC*/ case RCNR:
		sa_io.rcnr = data;
		break;
	case RTAR:
		sa_io.rtar = data;
		break;
	case RTSR:
		sa_io.rtsr |= (data & 0xc);
		sa_io.rtsr &= ~(data & 0x3);
		break;
	case RTTR:
		sa_io.rttr = data & 0x3ffffff;
		break;
		/*OS timer */
	case OSCR:
		sa_io.oscr = data;
		break;
	case OSMR0:
		sa_io.osmr0 = data;
		break;
	case OSMR1:
		sa_io.osmr1 = data;
		break;
	case OSMR2:
		sa_io.osmr2 = data;
		break;
	case OSMR3:
		sa_io.osmr3 = data;
		break;
	case OWER:
		sa_io.ower |= data & 0x1;
		break;
	case OSSR:
		sa_io.ossr &= ~(data & 0xf);
		break;
	case OIER:
		sa_io.oier = data & 0xf;
		break;

		/*interrupt control */
	case ICPR:
	case ICIP:
	case ICFP:
		/*read only */
		break;
	case ICMR:
		sa_io.icmr = data;
		break;
	case ICLR:
		sa_io.iclr = data;
		break;

		/*UART 3 */
	case UTCR0:
		sa_io.utcr0 = data & 0x7f;
		break;
	case UTCR1:
		sa_io.utcr1 = data & 0xf;
		break;
	case UTCR2:
		sa_io.utcr2 = data & 0xff;
		break;
	case UTCR3:
		sa_io.utcr3 = data & 0x3f;
		break;
	case UTDR:
		{
			char c = data;

			/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
			skyeye_uart_write(-1, &c, 1, NULL);

			//log_msg("UTDR write\n");
		}
		break;
	case UTSR0:
		sa_io.utsr0 &= ~(data & 0x1b);
		break;

	default:
		//log_msg("addr %x unknow\n", addr);
		;
	};

};

ARMword
sa_io_read_byte (ARMul_State * state, ARMword addr)
{
	printf ("SKYEYE: sa_io_read_byte error\n");
	skyeye_exit (-1);
}

ARMword
sa_io_read_halfword (ARMul_State * state, ARMword addr)
{
	printf ("SKYEYE: sa_io_read_halfword error\n");
	skyeye_exit (-1);
}

ARMword
sa_io_read_word (ARMul_State * state, ARMword addr)
{
	u32 data;

	switch (addr) {
	 /*RTC*/ case RCNR:
		data = sa_io.rcnr;
		break;
	case RTAR:
		data = sa_io.rtar;
		break;
	case RTSR:
		data = sa_io.rtsr;
		break;
	case RTTR:
		data = sa_io.rttr;
		break;

		/*OS timer */
	case OSCR:
		data = sa_io.oscr;
		break;
	case OSMR0:
		data = sa_io.osmr0;
		break;
	case OSMR1:
		data = sa_io.osmr1;
		break;
	case OSMR2:
		data = sa_io.osmr2;
		break;
	case OSMR3:
		data = sa_io.osmr3;
		break;
	case OWER:
		data = sa_io.ower;
		break;
	case OSSR:
		data = sa_io.ossr;
		break;
	case OIER:
		data = sa_io.oier;
		break;

		/*interrupt controler */
	case ICPR:
		data = sa_io.icpr;
		break;
	case ICIP:
		data = (sa_io.icmr & sa_io.icpr) & ~sa_io.iclr;
		break;
	case ICFP:
		data = (sa_io.icmr & sa_io.icpr) & sa_io.iclr;
		break;
	case ICMR:
		data = sa_io.icmr;
		break;
	case ICLR:
		data = sa_io.iclr;
		break;

		/*UART 3 */
	case UTCR0:
		data = sa_io.utcr0;
		break;
	case UTCR1:
		data = sa_io.utcr1;
		break;
	case UTCR2:
		data = sa_io.utcr2;
		break;
	case UTCR3:
		data = sa_io.utcr3;
		break;
	case UTDR:
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		data = (u32)sa_io.uart3_buf;

		sa_io.utsr0 = 1;	/*always TFS, no others */
		sa_io.utsr1 = 0x4;
		 /*TNF*/ break;
	case UTSR0:
		data = sa_io.utsr0;
		break;
	case UTSR1:
		data = sa_io.utsr1;
		break;

	default:
		//log_msg("addr %x unknow\n", addr);
		data = 0;
	};

	return data;
};


static void
sa_io_do_cycle (ARMul_State * state)
{
	 /*RTC*/ if (++sa_io.rt_scale >= RT_SCALE) {
		sa_io.rt_scale = 0;
		if (sa_io.rt_count++ == (sa_io.rttr & 0xffff)) {
			sa_io.rt_count = 0;

			if (sa_io.rcnr++ == sa_io.rtar) {
				if (sa_io.rtsr & 0x4) {
					sa_io.rtsr |= 0x1;
				};
			}
			if (sa_io.rtsr & 0x8) {
				sa_io.rtsr |= 0x2;
			}
		}
	};

	/*OS timer */
	if (++sa_io.os_scale >= OS_SCALE) {
		u32 mask = 0;
		u32 count;

		sa_io.os_scale = 0;
		count = sa_io.oscr++;

		if (count == sa_io.osmr0)
			mask = 1;
		if (count == sa_io.osmr1)
			mask |= 0x2;
		if (count == sa_io.osmr2)
			mask |= 0x4;
		if (count == sa_io.osmr3) {
			mask |= 0x8;
			if (sa_io.ower & 1)
				state->NresetSig = LOW;
		}
		sa_io.ossr |= mask;
	}

	/*UART 3 */
	if (++sa_io.uart3_scale > UART3_SCALE) {
		/* 2007-01-18 modified by Anthony Lee : for new uart device frame */
		struct timeval tv;

		tv.tv_sec = 0;
		tv.tv_usec = 0;

		sa_io.utsr0 |= 1;	/*always TFS, no others */
		sa_io.utsr1 |= 0x4;
		 /*TNF*/ sa_io.uart3_scale = 0;

		if(skyeye_uart_read(-1, &sa_io.uart3_buf, 1, &tv, NULL) > 0)
		{
			sa_io.utsr1 |= 0x2;	//RNE
			sa_io.utsr0 |= 0x4;	//RID
		}
	}

	/*reset interrupt pin status */
	refresh_irq (state);
};


static void
refresh_irq (ARMul_State * state)
{
	u32 irq = 0;
	u32 mask;

	 /*RTC*/ if ((sa_io.rtsr & 0x1) && (sa_io.rtsr & 0x4))
		irq |= RTC_ALARM_IRQ;
	if ((sa_io.rtsr & 0x2) && (sa_io.rtsr & 0x8))
		irq |= RTC_HZ_IRQ;
	/*OS time */
	mask = sa_io.oier & sa_io.ossr;
	irq |= (mask << OS_IRQ_SHF);

	/*UART3 */
	if ((sa_io.utcr3 & 0x8) && (sa_io.utsr0 & 0x6))
		irq |= UART3_IRQ;
	if (sa_io.utsr0 & 0x38)
		irq |= UART3_IRQ;

	if ((sa_io.utcr3 & 0x10) && (sa_io.utsr0 & 0x1))
		irq |= UART3_IRQ;

	sa_io.icpr = irq;
	sa_io.icip = (sa_io.icmr & sa_io.icpr) & ~sa_io.iclr;
	sa_io.icfp = (sa_io.icmr & sa_io.icpr) & sa_io.iclr;
	state->NirqSig = sa_io.icip ? LOW : HIGH;
	state->NfiqSig = sa_io.icfp ? LOW : HIGH;
}

void
sa1100_mach_init (ARMul_State * state, machine_config_t * mc)
{
	//chy 2003-08-19, setprocessor
	ARMul_SelectProcessor (state, ARM_v4_Prop);
	//chy 2004-05-09, set lateabtSig
	state->lateabtSig = LOW;


	state->Reg[1] = 109;	/*adsbitsy machine id. */
	sa_io_reset ();
	mc->mach_io_do_cycle = sa_io_do_cycle;
	mc->mach_io_reset = sa_io_reset;
	mc->mach_io_read_byte = sa_io_read_byte;
	mc->mach_io_write_byte = sa_io_write_byte;
	mc->mach_io_read_halfword = sa_io_read_halfword;
	mc->mach_io_write_halfword = sa_io_write_halfword;
	mc->mach_io_read_word = sa_io_read_word;
	mc->mach_io_write_word = sa_io_write_word;
}
