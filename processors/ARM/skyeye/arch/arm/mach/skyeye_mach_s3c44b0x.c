/*
	skyeye_mach_s3c44b0x.c - SAMSUNG's S3C44B0X simulation for skyeye
	Copyright (C) 2003 - 2007 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.gro.clinux.org>

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
 * 07/19/2003	original implementation by Walimis <wlm@student.dlut.edu.cn>
 * 03/04/2007	rewritten by Anthony Lee <don.anthony.lee+program@gmail.com>
 */

/*
 * COMPLETED: Interrupt, UART, PWM Timers, Watchdog Timer, LCD, NET, RTC, DMA, IIS
 * UNIMPLEMENTED: I/O Ports, etc.
 *
 * NOTE:
 * 	LCD: see "device/lcd/dev_lcd_s3c44b0x.c[h]"
 * 	SOUND: see "device/sound/dev_sound_s3c44b0x.c"
 * 	NET(RTL8019AS 8/16 bits): see "device/net/dev_net_rtl8019.c[h]"
 */

#include "armdefs.h"
#include "armemu.h"
#include "s3c44b0.h"
#include "skyeye_uart.h"
#include "portable/gettimeofday.h"

#define S3C44B0X_DEBUG			0

#define PRINT(x...)			printf("[S3C44B0X]: " x)

#if S3C44B0X_DEBUG
#define DEBUG(x...)			printf("[S3C44B0X]: " x)
#else
#define DEBUG(x...)			(void)0
#endif

/*
 * CYCLE_TIMES_PER_SECOND:
 * 	It's near 40000 times on my machine,
 * 	you can change the value to fit your machine.
 */
#define CYCLE_TIMES_PER_SECOND		(40000)

#define MCLK				(64) /* MHz */
#define TIMER_COUNT_DOWN_PER_SECOND	((1000000 * MCLK) >> 1) /* prescale=1, divider=1/2 */
#define TIMER_COUNT_DOWN_PER_CYCLE	(TIMER_COUNT_DOWN_PER_SECOND / CYCLE_TIMES_PER_SECOND)

#define BCD_TO_BIN(a)			(((a) >> 4) * 10 + ((a) & 0xf))
#define BIN_TO_BCD(a)			((((a) / 10) << 4) | ((a) % 10))
#define HALFWORD_SWAP(x)		(((x) >> 8) | ((x) << 8))
#define WORD_SWAP(x)			((HALFWORD_SWAP((x) & 0xffff) << 16) | HALFWORD_SWAP(((x) >> 16) & 0xffff))

struct s3c44b0x_uart_fifo
{
	unsigned char rx[16];
	unsigned char tx[16];
	ARMword txcnt;
};

typedef ARMword (s3c44b0x_dma_t)[8];
#define DMA_CON(dma)			dma[0]
#define DMA_ISRC(dma)			dma[1]
#define DMA_IDES(dma)			dma[2]
#define DMA_ICNT(dma)			dma[3]
#define DMA_CSRC(dma)			dma[4]
#define DMA_CDES(dma)			dma[5]
#define DMA_CCNT(dma)			dma[6]
#define DMA_FLY(dma)			dma[7]

extern ARMword mem_read_byte(ARMul_State*, ARMword);
extern ARMword mem_read_halfword(ARMul_State*, ARMword);
extern ARMword mem_read_word(ARMul_State*, ARMword);
extern void mem_write_byte(ARMul_State*, ARMword, ARMword);
extern void mem_write_halfword(ARMul_State*, ARMword, ARMword);
extern void mem_write_word(ARMul_State*, ARMword, ARMword);

extern ARMword io_read_byte(ARMul_State*, ARMword);
extern ARMword io_read_halfword(ARMul_State*, ARMword);
extern ARMword io_read_word(ARMul_State*, ARMword);
extern void io_write_byte(ARMul_State*, ARMword, ARMword);
extern void io_write_halfword(ARMul_State*, ARMword, ARMword);
extern void io_write_word(ARMul_State*, ARMword, ARMword);

typedef ARMword (*s3c44b0x_dma_read_func)(ARMul_State*, ARMword);
typedef void (*s3c44b0x_dma_write_func)(ARMul_State*, ARMword, ARMword);

static s3c44b0x_dma_read_func dma_read_funcs[12] = {
	/* ZDMA */
	mem_read_byte,
	mem_read_halfword,
	mem_read_word,

	/* BDMA */
	mem_read_byte,		io_read_byte,		io_read_byte,
	mem_read_halfword,	io_read_halfword,	io_read_halfword,
	mem_read_word,		io_read_word,		io_read_word,
};

static s3c44b0x_dma_write_func dma_write_funcs[12] = {
	/* ZDMA */
	mem_write_byte,
	mem_write_halfword,
	mem_write_word,

	/* BDMA */
	io_write_byte,		mem_write_byte,		io_write_byte,
	io_write_halfword,	mem_write_halfword,	io_write_halfword,
	io_write_word,		mem_write_word,		io_write_word,
};

/* S3C44B0X Internal IO Registers */
struct s3c44b0x_io_t
{
	/* CPU Wrapper Registers : FIXME */
	ARMword syscfg;
	ARMword ncachbe0;
	ARMword ncachbe1;
	ARMword sbuscon;

	/* Memory Controller Registers : FIXME */
	ARMword bwscon;

	/* Interrupt Controller Registers */
	ARMword intcon;
	ARMword intpnd;
	ARMword intmod;
	ARMword intmsk;
	ARMword i_pslv;
	ARMword i_pmst;
	ARMword i_cslv;
	ARMword i_cmst;

	/* UART Registers */
	ARMword ulcon0;
	ARMword ulcon1;
	ARMword ucon0;
	ARMword ucon1;
	ARMword ufcon0;
	ARMword ufcon1;
	ARMword umcon0;
	ARMword umcon1;
	ARMword utrstat0;
	ARMword utrstat1;
	ARMword uerstat0;
	ARMword uerstat1;
	ARMword ufstat0;
	ARMword ufstat1;
	ARMword umstat0;
	ARMword umstat1;
	ARMword urxh0;
	ARMword urxh1;
	ARMword ubrdiv0;
	ARMword ubrdiv1;
	struct s3c44b0x_uart_fifo ufifo0;
	struct s3c44b0x_uart_fifo ufifo1;

	/* PWM Timers Registers */
	ARMword tcfg0;
	ARMword tcfg1;
	ARMword tcnt_scaler[7];
	ARMword tprescaler[7];
	ARMword tdivider[7];
	ARMword tcon;
	ARMword tcntb[6];
	ARMword tcmpb[5];
	ARMword tcnt[6];
	ARMword tcmp[5];

	/* Watchdog Timer Registers */
	ARMword wtcon;
	ARMword wtdat;
	ARMword wtcnt;

	/* RTC Registers */
	ARMword rtccon;
	ARMword rtcalm;
	ARMword rtcrst;
	ARMword ticint;
	ARMword tick_count;
	struct tm rtc_alarm;
	long int rtc_offset;

	/* DMA Registers */
	s3c44b0x_dma_t dma[4];

	/* IIS Registers */
	ARMword iiscon;
	ARMword iismod;
	ARMword iispsr;
	ARMword iisfifcon;
	ARMhword iisfifo_rx[8];
	ARMhword iisfifo_tx[8];
	ARMword iisfifo_txcnt;
};

static struct s3c44b0x_io_t s3c44b0x_io;
ARMhword *s3c44b0x_iisfifo_tx = NULL;
#define io s3c44b0x_io

static int s3c44b0x_dma_is_valid(int index);
static void s3c44b0x_dma_proccess(ARMul_State *state, int index);


static void s3c44b0x_io_reset(ARMul_State *state)
{
	memset(&io, 0, sizeof(io));

	/* CPU Wrapper */
	io.syscfg = 0x1;
	io.sbuscon = 0x80001b1b;

	/* Memory Controller */
	io.bwscon = (state->bigendSig ? 0x1 : 0x0);

	/* Interrupt */
	io.intcon = 0x7;
	io.intmsk = 0x7ffffff;
	io.i_pslv = 0x1b1b1b1b;
	io.i_pmst = 0x1f1b;
	io.i_cslv = 0x1b1b1b1b;
	io.i_cmst = 0x1b;

	/* UART */
	io.utrstat0 = io.utrstat1 = 0x6;

	/* Watchdog Timer */
	io.wtcon = 0x8020; /* here we disabled watchdog */
	io.wtdat = 0x8000;
	io.wtcnt = 0x8000;
	io.tdivider[6] = 4;

	/* RTC */
	io.rtc_alarm.tm_mday = 1;

	/* IIS */
	io.iiscon = 0x100;
	s3c44b0x_iisfifo_tx = &io.iisfifo_tx[0];
}


/* Interrupt Routine */
static void s3c44b0x_update_int(ARMul_State *state)
{
	ARMword requests = (io.intmsk & (0x1 << INT_GLOBAL)) ? 0x0 : (io.intpnd & ~io.intmsk);
	ARMword vector, irq;

	state->NfiqSig = ((io.intcon & 0x1) == 0 ? ((requests & io.intmod) ? LOW : HIGH) : HIGH);
	state->NirqSig = ((io.intcon & 0x2) == 0 ? ((requests & ~io.intmod) ? LOW : HIGH) : HIGH);
}


static void s3c44b0x_update_intr(struct machine_config *mach)
{
	/* leave me alone, do nothing ... */
}


static int s3c44b0x_pending_intr(unsigned int irq)
{
	/* Here we "return 1" so that the device won't do something for it */
	if (!((io.intcon & 0x2) == 0x0 || (io.intcon & 0x5) == 0x4)) return 1;
	if (io.intmsk & (0x1 << INT_GLOBAL)) return 1;

	return ((io.intpnd & (0x1 << irq)) == 0 ? 0 : 1);
}


static void s3c44b0x_set_interrupt(unsigned int irq)
{
	if ((io.intcon & 0x2) == 0x0 || (io.intcon & 0x5) == 0x4) { /* IRQ or FIQ enabled */
		io.intpnd |= (0x1 << irq);
	}
}


static void s3c44b0x_interrupt_read(ARMword addr, ARMword *data)
{
	int i;

	switch (addr) {
		case INTCON:
			*data = io.intcon;
			break;

		case INTPND:
			*data = ((io.intmsk & (0x1 << INT_GLOBAL)) ? 0x1 : io.intpnd);
			break;

		case INTMOD:
			*data = io.intmod;
			break;

		case INTMSK:
			*data = io.intmsk;
			break;

		case I_PSLV:
			*data = io.i_pslv;
			break;

		case I_PMST:
			*data = io.i_pmst;
			break;

		case I_CSLV:
			*data = io.i_cslv;
			break;

		case I_CMST:
			*data = io.i_cmst;
			break;

		case I_ISPR:
			*data = 0;
			if (io.intmsk & (0x1 << INT_GLOBAL)) break;
			if ((io.intcon & 0x2) != 0x0) break;
			for (i = 0; i < 26; i++) { /* find which interrupt is pending */
				if (((io.intpnd & ~io.intmsk) & (0x1 << i)) & ~io.intmod) {
					*data = (0x1 << i);
					break;
				}
			}
			break;

		case F_ISPR:
			*data = 0;
			if (io.intmsk & (0x1 << INT_GLOBAL)) break;
			if ((io.intcon & 0x5) != 0x4) break;
			for (i = 0; i < 26; i++) { /* find which interrupt is pending */
				if (((io.intpnd & ~io.intmsk) & (0x1 << i)) & io.intmod) {
					*data = (0x1 << i);
					break;
				}
			}
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_interrupt_write(ARMul_State *state, ARMword addr, ARMword data)
{
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case INTCON:
			io.intcon = data;
			break;

		case INTMOD:
			io.intmod = data;
			break;

		case INTMSK:
			io.intmsk = data;
			break;

		case I_PSLV:
			io.i_pslv = data;
			break;

		case I_PMST:
			io.i_pmst = data;
			break;

		case I_ISPC:
			if ((io.intcon & 0x2) != 0x0 || ((data & 0x3ffffff) & ~io.intmod) == 0) break;
			io.intpnd &= (~data & 0x3ffffff);
			break;

		case F_ISPC:
			if ((io.intcon & 0x5) != 0x4 || ((data & 0x3ffffff) & io.intmod) == 0) break;
			io.intpnd &= (~data & 0x3ffffff);
			break;

		default:
			break;
	}
}


/* UART Routine */
static void s3c44b0x_uart_do_cycle(ARMul_State *state)
{
	int read_uart0 = 1;
	struct timeval tv;

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	do {
		ARMword *pUfstat = (read_uart0 ? &io.ufstat0 : &io.ufstat1);
		ARMword *pUtrstat = (read_uart0 ? &io.utrstat0 : &io.utrstat1);
		ARMword *pUcon = (read_uart0 ? &io.ucon0 : &io.ucon1);
		ARMword *pUfcon = (read_uart0 ? &io.ufcon0 : &io.ufcon1);
		ARMword *pUrxh = (read_uart0 ? &io.urxh0 : &io.urxh1);
		ARMword bdma_mask = (read_uart0 ? 0x2 : 0x3);

		if ((*pUcon & 0x3) == bdma_mask || (*pUcon & 0xc) == (bdma_mask << 2)) { /* BDMA request */
			ARMword utxhb = (read_uart0 ? UTXH0 : UTXH1) + state->bigendSig * 3;
			ARMword urxhb = (read_uart0 ? URXH0 : URXH1) + state->bigendSig * 3;
			int index = (read_uart0 ? 2 : 3);
			int rx_empty = ((*pUfcon & 0x1) ? ((*pUfstat & 0xf) == 0) : ((*pUtrstat & 0x1) == 0));
			int tx_ready = ((*pUfcon & 0x1) ? ((*pUfstat & 0x200) == 0) : 1);
			ARMword mask = 0;

			if ((*pUcon & 0x3) == 0x0) rx_empty = 1;
			if ((*pUcon & 0xc) == 0x0) tx_ready = 0;

			do {
				if (s3c44b0x_dma_is_valid(index) != 1) break;
				if (((DMA_CCNT(io.dma[index]) >> 30) & 0x3) != 0x2) break;

				if ((DMA_CDES(io.dma[index]) & 0xfffffff) == utxhb && tx_ready) mask |= (bdma_mask << 2);
				if ((DMA_CSRC(io.dma[index]) & 0xfffffff) == urxhb && !rx_empty) mask |= bdma_mask;
				if ((*pUcon & mask) != 0) s3c44b0x_dma_proccess(state, index);
			} while (0);
		}

		if (*pUfcon & 0x1) { /* FIFO mode */
			struct s3c44b0x_uart_fifo *pUfifo = (read_uart0 ? &io.ufifo0 : &io.ufifo1);
			int count, tmp_count;

			if ((*pUfstat & 0x100) == 0 && (*pUcon & 0x3) != 0x0) { /* FIFO not full */
				tmp_count = count = (*pUfstat & 0xf);
				count += skyeye_uart_read(read_uart0 ? 0 : 1, &pUfifo->rx[count], 16 - count, &tv, NULL);

				if (count > tmp_count) {
					*pUfstat &= ~0xf;
					*pUfstat |= (count == 16 ? 0x10f : count);
				}
			}

			while ((count = ((*pUfstat & 0xf0) >> 4)) > 0 && (*pUcon & 0xc) != 0x0) { /* handling TX FIFO */
				if (pUfifo->txcnt > 0) {
					pUfifo->txcnt -= 1;
					break;
				}

				if (*pUfstat & 0x200) count++;
				tmp_count = skyeye_uart_write(read_uart0 ? 0 : 1, &pUfifo->tx[0], count, NULL);
				if (tmp_count <= 0) break;

				count -= tmp_count;

				*pUfstat &= ~0x2f0;
				if (count > 0) {
					*pUfstat |= (count << 4);
					memmove(&pUfifo->tx[0], &pUfifo->tx[tmp_count], (size_t)count);
				} else {
					pUfifo->txcnt = 64;
				}

				if ((*pUcon & 0xc) == 0x4) { /* Transmit Mode: Interrupt request or polling mode */
					s3c44b0x_set_interrupt(read_uart0 ? INT_UTXD0 : INT_UTXD1);
				}

				break;
			}

			if ((*pUfstat & 0xf) == 0) continue;
			*pUrxh = (ARMword)pUfifo->rx[0];

		} else { /* non FIFO mode */
			unsigned char buf;

			if ((*pUcon & 0x3) == 0x0) continue;
			if (*pUtrstat & 0x1) continue;
			if (skyeye_uart_read(read_uart0 ? 0 : 1, &buf, 1, &tv, NULL) <= 0) continue;

			*pUrxh = (ARMword)buf;
			*pUtrstat |= 0x1;
		}

		if ((*pUcon & 0x3) == 0x1) s3c44b0x_set_interrupt(read_uart0 ? INT_URXD0 : INT_URXD1);
	} while((read_uart0--) && skyeye_config.uart.count > 1);
}


static void s3c44b0x_uart_read(ARMword addr, ARMword *data)
{
	switch (addr) {
		case ULCON0:
			*data = io.ulcon0;
			break;
		case ULCON1:
			*data = io.ulcon1;
			break;

		case UCON0:
			*data = io.ucon0;
			break;
		case UCON1:
			*data = io.ucon1;
			break;

		case UFCON0:
			*data = io.ufcon0;
			break;
		case UFCON1:
			*data = io.ufcon1;
			break;

		case UMCON0:
			*data = io.umcon0;
			break;
		case UMCON1:
			*data = io.umcon1;
			break;

		case UTRSTAT0:
			*data = io.utrstat0;
			break;
		case UTRSTAT1:
			*data = io.utrstat1;
			break;

		case UERSTAT0:
			*data = io.uerstat0;
			break;
		case UERSTAT1:
			*data = io.uerstat1;
			break;

		case UFSTAT0:
			*data = io.ufstat0;
			break;
		case UFSTAT1:
			*data = io.ufstat1;
			break;

		case UMSTAT0:
			*data = io.umstat0;
			break;
		case UMSTAT1:
			*data = io.umstat1;
			break;

		case URXH0:
		case URXH1:
			{
				ARMword *pUfstat = (addr == URXH0 ? &io.ufstat0 : &io.ufstat1);
				ARMword *pUtrstat = (addr == URXH0 ? &io.utrstat0 : &io.utrstat1);
				ARMword *pUfcon = (addr == URXH0 ? &io.ufcon0 : &io.ufcon1);
				ARMword *pUrxh = (addr == URXH0 ? &io.urxh0 : &io.urxh1);

				*data = (*pUrxh);

				if (*pUfcon & 0x1) { /* FIFO mode */
					ARMword *pUcon = (addr == URXH0 ? &io.ucon0 : &io.ucon1);
					struct s3c44b0x_uart_fifo *pUfifo = (addr == URXH0 ? &io.ufifo0 : &io.ufifo1);
					int count = (*pUfstat & 0xf);

					if (count == 0) break;
					if (*pUfstat & 0x100) count++;
					*pUfstat &= ~0x10f;
					if (count == 1) break;

					*pUfstat |= (--count);
					memmove(&pUfifo->rx[0], &pUfifo->rx[1], (size_t)count);
					*pUrxh = (ARMword)pUfifo->rx[0];
				} else { /* non FIFO mode */
					*pUtrstat &= ~0x1;
				}
			}
			break;

		case UBRDIV0:
			*data = io.ubrdiv0;
			break;
		case UBRDIV1:
			*data = io.ubrdiv1;
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_uart_write(ARMul_State *state, ARMword addr, ARMword data)
{
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case ULCON0:
			io.ulcon0 = data;
			break;
		case ULCON1:
			io.ulcon1 = data;
			break;

		case UCON0:
			io.ucon0 = data;
			break;
		case UCON1:
			io.ucon1 = data;
			break;

		case UFCON0:
		case UFCON1:
			{
				ARMword *pUfcon = (addr == UFCON0 ? &io.ufcon0 : &io.ufcon1);
				*pUfcon = (data & ~0x6);

				if (!((data & 0x1) == 0 || (data & 0x6) == 0)) {
					ARMword *pUfstat = (addr == UFCON0 ? &io.ufstat0 : &io.ufstat1);
					if (data & 0x2) *pUfstat &= ~0x10f; /* Rx FIFO reset */
					if (data & 0x4) *pUfstat &= ~0x2f0; /* Tx FIFO reset */
				}
			}
			break;

		case UMCON0:
			io.umcon0 = data;
			break;
		case UMCON1:
			io.umcon1 = data;
			break;

		case UTXH0:
		case UTXH1:
			{
				ARMword *pUtrstat = (addr == UTXH0 ? &io.utrstat0 : &io.utrstat1);
				ARMword *pUcon = (addr == UTXH0 ? &io.ucon0 : &io.ucon1);
				ARMword *pUfcon = (addr == UTXH0 ? &io.ufcon0 : &io.ufcon1);
				char tmp = data & 0xff;

#if 0
				/* Disabled the line to show some messages when booting use incorrect bootrom */
				if ((*pUcon & 0xc) == 0x0) break;
#endif

				if (*pUfcon & 0x1) { /* FIFO mode */
					ARMword *pUfstat = (addr == UTXH0 ? &io.ufstat0 : &io.ufstat1);

					if ((*pUfstat & 0x200) == 0) { /* FIFO not full */
						struct s3c44b0x_uart_fifo *pUfifo = (addr == UTXH0 ? &io.ufifo0 : &io.ufifo1);
						int count = ((*pUfstat >> 4) & 0xf);

						pUfifo->tx[count++] = tmp;
						*pUfstat &= ~0xf0;
						*pUfstat |= (count == 16 ? 0x2f0 : (count << 4));
					}

				} else { /* non FIFO mode */
					skyeye_uart_write(addr == UTXH0 ? 0 : 1, (void*)&tmp, 1, NULL);
					*pUtrstat |= 0x6;

					if ((*pUcon & 0xc) == 0x4) { /* Transmit Mode: Interrupt request or polling mode */
						s3c44b0x_set_interrupt(addr == UTXH0 ? INT_UTXD0 : INT_UTXD1);
					}
				}
			}
			break;

		case UBRDIV0:
			io.ubrdiv0 = data;
			break;
		case UBRDIV1:
			io.ubrdiv1 = data;
			break;

		default:
			break;
	}
}


/* Timer Routine */
static int s3c44b0x_timer_check_state(int timer_index, int op_code)
{
	int bit_offset;

	if (timer_index == 5) {
		switch (op_code) {
			case TIMER_OP_START:
				bit_offset = 24;
				break;

			case TIMER_OP_MANUAL:
				bit_offset = 25;
				break;

			case TIMER_OP_RELOAD:
				bit_offset = 26;
				break;

			default:
				return 0; /* invalid */
		}
	} else {
		bit_offset = op_code + (timer_index == 0 ? 0 : 8 + 4 * (timer_index - 1));
	}

	return (io.tcon & (0x1 << bit_offset));
}


static void s3c44b0x_timer_do_cycle(ARMul_State *state)
{
	int i, cnt_down, cnt_divider;

	for (i = 0; i < 6; i++) {

		if (s3c44b0x_timer_check_state(i, TIMER_OP_START) == 0) continue;

		cnt_divider = (io.tprescaler[i] + 1) << io.tdivider[i];
		cnt_down = TIMER_COUNT_DOWN_PER_CYCLE / cnt_divider;
		if (cnt_down == 0) {
			if (io.tcnt_scaler[i] == 0) {
				io.tcnt_scaler[i] = cnt_divider / TIMER_COUNT_DOWN_PER_CYCLE;
				continue;
			} else if ((io.tcnt_scaler[i] -= 1) != 0) {
				continue;
			}
			cnt_down = 1;
		}

		if ((io.tcnt[i] -= min(io.tcnt[i], cnt_down)) > 0) continue;

		if (((io.tcfg1 >> 24) & 0xf) == i + 1) { /* BDMA request */
			do {
				if (s3c44b0x_dma_is_valid(3) != 1) break;
				if (((DMA_CCNT(io.dma[3]) >> 30) & 0x3) != 0x1) break;
				s3c44b0x_dma_proccess(state, 3);
			} while (0);
		} else { /* interrupt mode */
			s3c44b0x_set_interrupt(INT_TIMER0 - i);
		}

		if (s3c44b0x_timer_check_state(i, TIMER_OP_RELOAD) == 0) continue;

		io.tcnt[i] = io.tcntb[i];
		if (i < 5) io.tcmp[i] = io.tcmpb[i];
	}

	if (io.wtcon & 0x20) {
		cnt_divider = (io.tprescaler[6] + 1) << io.tdivider[6];
		cnt_down = TIMER_COUNT_DOWN_PER_CYCLE / cnt_divider;
		if (cnt_down == 0) {
			if (io.tcnt_scaler[6] == 0) {
				io.tcnt_scaler[6] = cnt_divider / TIMER_COUNT_DOWN_PER_CYCLE;
				goto next;
			} else if ((io.tcnt_scaler[6] -= 1) != 0) {
				goto next;
			}
			cnt_down = 1;
		}

		if ((io.wtcnt -= min(io.wtcnt, cnt_down)) > 0) return;

		if ((io.wtcon & 0x4) != 0) { /* interrupt mode */
			s3c44b0x_set_interrupt(INT_WDT);
		}

		if (io.wtcon & 0x1) { /* asserts reset signal */
			state->NresetSig = LOW;
			PRINT("****************** WATCHDOG RESET ******************\n");
		}

		io.wtcnt = io.wtdat;
	}

next:
	return;
}


static void s3c44b0x_timer_read(ARMword addr, ARMword *data)
{
	switch (addr) {
		case TCFG0:
			*data = io.tcfg0;
			break;

		case TCFG1:
			*data = io.tcfg1;
			break;

		case TCON:
			*data = io.tcon;
			break;

		case TCNTB0:
		case TCNTB1:
		case TCNTB2:
		case TCNTB3:
		case TCNTB4:
		case TCNTB5:
			*data = io.tcntb[(addr - TCNTB0) / 0xc];
			break;

		case TCMPB0:
		case TCMPB1:
		case TCMPB2:
		case TCMPB3:
		case TCMPB4:
			*data = io.tcmpb[(addr - TCMPB0) / 0xc];
			break;

		case TCNTO0:
		case TCNTO1:
		case TCNTO2:
		case TCNTO3:
		case TCNTO4:
			*data = io.tcnt[(addr - TCNTO0) / 0xc];
			break;

		case TCNTO5:
			*data = io.tcnt[5];
			break;

		case WTCON:
			*data = io.wtcon;
			break;

		case WTDAT:
			*data = io.wtdat;
			break;

		case WTCNT:
			*data = io.wtcnt;
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_timer_write(ARMul_State *state, ARMword addr, ARMword data)
{
	int i, prescaler, divider;

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case TCFG0:
		case TCFG1:
			if (addr == TCFG0) {
				io.tcfg0 = data;
			} else {
				io.tcfg1 = data;
			}
			for (i = 0; i < 6; i++) {
				io.tprescaler[i] = ((io.tcfg0 >> ((i >> 1) << 3)) & 0xff);
				io.tdivider[i] = min(4, ((io.tcfg1 >> (i << 2)) & 0xf));
			}
			break;

		case TCON:
			io.tcon = data;
			for (i = 0; i < 6; i++) {
				if (s3c44b0x_timer_check_state(i, TIMER_OP_MANUAL) != 0) {
					io.tcnt[i] = io.tcntb[i];
					if (i < 5) io.tcmp[i] = io.tcmpb[i];
				}
			}
			break;

		case TCNTB0:
		case TCNTB1:
		case TCNTB2:
		case TCNTB3:
		case TCNTB4:
		case TCNTB5:
			io.tcntb[(addr - TCNTB0) / 0xc] = min(data, 0xffff);
			break;

		case TCMPB0:
		case TCMPB1:
		case TCMPB2:
		case TCMPB3:
		case TCMPB4:
			io.tcmpb[(addr - TCMPB0) / 0xc] = data;
			break;

		case WTCON:
			io.wtcon = data;
			io.tprescaler[6] = ((io.wtcon >> 8) & 0xff);
			io.tdivider[6] = ((io.wtcon >> 3) & 0x3) + 4;
			break;

		case WTDAT:
			io.wtdat = data;
			break;

		case WTCNT:
			io.wtcnt = data;
			break;

		default:
			break;
	}
}


/* I/O Ports Routine */
static void s3c44b0x_ports_read(ARMword addr, ARMword *data)
{
	/* TODO */
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_ports_write(ARMul_State *state, ARMword addr, ARMword data)
{
	/* TODO */
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);
}


/* RTC Routine */
static void s3c44b0x_rtc_do_cycle(ARMul_State *state)
{
	if ((io.rtcalm & 0x40) != 0 && (io.rtcalm & 0x3f) != 0) {
		struct timeval curr_time;
		struct tm *curr_tm;
		time_t curr_timer;
		unsigned int almen = 0;

		if (gettimeofday(&curr_time, NULL) != 0 ||
		    ((curr_timer = (time_t)((long int)curr_time.tv_sec + io.rtc_offset)),
		     (curr_tm = gmtime(&curr_timer))) == NULL) return;

		if (curr_tm->tm_sec >= io.rtc_alarm.tm_sec) almen |= 0x1;
		if (curr_tm->tm_min == io.rtc_alarm.tm_min) almen |= 0x2;
		if (curr_tm->tm_hour == io.rtc_alarm.tm_hour) almen |= 0x4;
		if (curr_tm->tm_mday == io.rtc_alarm.tm_mday) almen |= 0x8;
		if (curr_tm->tm_mon == io.rtc_alarm.tm_mon) almen |= 0x10;
		if (curr_tm->tm_year == io.rtc_alarm.tm_year) almen |= 0x20;

		if ((io.rtcalm & 0x3f) == almen) {
			io.rtcalm &= 0x3f;
			s3c44b0x_set_interrupt(INT_RTC);
		}
	}

	if ((io.ticint & 0x80) != 0) { /* WARNING: RTC tick is unexacting */
		if (io.tick_count > 0) io.tick_count -= 1;
		if (io.tick_count == 0) s3c44b0x_set_interrupt(INT_TICK);
	}
}


static void s3c44b0x_rtc_read(ARMword addr, ARMword *data)
{
	struct timeval curr_time;
	struct tm *curr_tm;
	time_t curr_timer;

	if (addr == RTCCON) {
		*data = io.rtccon;
		goto exit;
	} else if ((io.rtccon & 0x1) == 0) {
		goto exit;
	}

	switch (addr) {
		case RTCALM:
			*data = io.rtcalm;
			goto exit;

		case RTCRST:
			*data = io.rtcrst;
			goto exit;

		case TICINT:
			*data = io.ticint;
			goto exit;

		case ALMSEC:
			*data = BIN_TO_BCD(io.rtc_alarm.tm_sec);
			goto exit;

		case ALMMIN:
			*data = BIN_TO_BCD(io.rtc_alarm.tm_min);
			goto exit;

		case ALMHOUR:
			*data = BIN_TO_BCD(io.rtc_alarm.tm_hour);
			goto exit;

		case ALMDAY:
			*data = BIN_TO_BCD(io.rtc_alarm.tm_mday);
			goto exit;

		case ALMMON:
			*data = BIN_TO_BCD(io.rtc_alarm.tm_mon + 1);
			goto exit;

		case ALMYEAR:
			*data = io.rtc_alarm.tm_year - 100;
			goto exit;

		default:
			break;
	}

	if (gettimeofday(&curr_time, NULL) != 0 ||
	    ((curr_timer = (time_t)((long int)curr_time.tv_sec + io.rtc_offset)),
	     (curr_tm = gmtime(&curr_timer))) == NULL) goto exit;

	switch (addr) {
		case BCDSEC:
			*data = BIN_TO_BCD(curr_tm->tm_sec);
			break;

		case BCDMIN:
			*data = BIN_TO_BCD(curr_tm->tm_min);
			break;

		case BCDHOUR:
			*data = BIN_TO_BCD(curr_tm->tm_hour);
			break;

		case BCDDAY:
			*data = BIN_TO_BCD(curr_tm->tm_mday);
			break;

		case BCDDATE:
			*data = (curr_tm->tm_wday == 0 ? 7 : curr_tm->tm_wday);
			break;

		case BCDMON:
			*data = BIN_TO_BCD(curr_tm->tm_mon + 1);
			break;

		case BCDYEAR:
			*data = curr_tm->tm_year - 100;
			break;

		default:
			goto exit;
	}

exit:
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
	return;
}


static void s3c44b0x_rtc_write(ARMul_State *state, ARMword addr, ARMword data)
{
	struct timeval curr_time;
	struct tm *curr_tm;
	time_t curr_timer;

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	if (addr == RTCCON) {
		io.rtccon = data;
		goto exit;
	} else if ((io.rtccon & 0x1) == 0) {
		goto exit;
	}

	switch (addr) {
		case RTCALM:
			io.rtcalm = data;
			goto exit;

		case RTCRST:
			io.rtcrst = data;
			goto exit;

		case TICINT:
			io.ticint = data;
			io.tick_count = (data & 0x7f);
			io.tick_count *= (CYCLE_TIMES_PER_SECOND / 128); /* 1/128 sec per count down */
			goto exit;

		case ALMSEC:
			io.rtc_alarm.tm_sec = BCD_TO_BIN(data);
			goto exit;

		case ALMMIN:
			io.rtc_alarm.tm_min = BCD_TO_BIN(data);
			goto exit;

		case ALMHOUR:
			io.rtc_alarm.tm_hour = BCD_TO_BIN(data);
			goto exit;

		case ALMDAY:
			io.rtc_alarm.tm_mday = BCD_TO_BIN(data);
			goto exit;

		case ALMMON:
			io.rtc_alarm.tm_mon = BCD_TO_BIN(data) - 1;
			goto exit;

		case ALMYEAR:
			io.rtc_alarm.tm_year = data + 100;
			goto exit;

		default:
			break;
	}

	if (gettimeofday(&curr_time, NULL) != 0 ||
	    ((curr_timer = (time_t)((long int)curr_time.tv_sec + io.rtc_offset)),
	     (curr_tm = gmtime(&curr_timer))) == NULL) goto exit;

	switch (addr) {
		case BCDSEC:
			curr_tm->tm_sec = BCD_TO_BIN(data);
			break;

		case BCDMIN:
			curr_tm->tm_min = BCD_TO_BIN(data);
			break;

		case BCDHOUR:
			curr_tm->tm_hour = BCD_TO_BIN(data);
			break;

		case BCDDAY:
			curr_tm->tm_mday = BCD_TO_BIN(data);
			break;

		case BCDDATE:
			break;

		case BCDMON:
			curr_tm->tm_mon = BCD_TO_BIN(data) - 1;
			break;

		case BCDYEAR:
			curr_tm->tm_mon = data + 100;
			break;

		default:
			goto exit;
	}

	io.rtc_offset = (long int)mktime(curr_tm) - (long int)curr_time.tv_sec;

exit:
	return;
}


/* DMA Routine */
static void s3c44b0x_dma_proccess(ARMul_State *state, int index)
{
	int i = index;
	int dal, das, dst, opt_tdm;
	s3c44b0x_dma_read_func read_func;
	s3c44b0x_dma_write_func write_func;
	ARMword ccnt, src_addr, dst_addr, data;

	ccnt = DMA_CCNT(io.dma[i]);
	if ((ccnt & 0xfffff) == 0x0) {
		if ((ccnt & 0x200000) == 0x0) return;
		memcpy(&io.dma[i][4], &io.dma[i][1], 3 * sizeof(ARMword)); /* auto-reload */
		DMA_CON(io.dma[i]) &= ~0x30;
		DMA_CCNT(io.dma[i]) &= ~0x3000000;
		return;
	}

	src_addr = DMA_CSRC(io.dma[i]);
	dst_addr = DMA_CDES(io.dma[i]);
	if ((dal = ((src_addr >> 28) & 0x3)) == 0x0) return;
	if ((das = ((dst_addr >> 28) & 0x3)) == 0x0) return;
	if ((dst = ((src_addr >> 30) & 0x3)) == 0x3) return;
	if (i < 2 && dst != 0x2 && ((ccnt >> 26) & 0x3) == 0x2) return;
	if ((opt_tdm = ((dst_addr >> 30) & 0x3)) == 0x0 && i >= 2) return;

	if ((ccnt & 0xfffff) >= (1 << dst)) {
		read_func = dma_read_funcs[i < 2 ? dst : (3 + (dst * 3) + (opt_tdm - 1))];
		write_func = dma_write_funcs[i < 2 ? dst : (3 + (dst * 3) + (opt_tdm - 1))];

		if (((ccnt >> 26) & 0x3) != 0x3 || ((ccnt >> 24) & 0x3) != 0x2) { /* read */
			data = (*read_func)(state, (src_addr & 0xfffffff));

			if (i < 2 && dst != 0 && (opt_tdm & 0x1) != 0x0) /* swap */
				data = (dst == 1 ? HALFWORD_SWAP(data) : WORD_SWAP(data));

			if (dal == 1) src_addr += min(0xfffffff - (src_addr & 0xfffffff), 1 << dst);
			else if (dal == 2) src_addr -= min((src_addr & 0xfffffff), 1 << dst);

			DMA_CSRC(io.dma[i]) = src_addr;
		}

		if (((ccnt >> 26) & 0x3) != 0x3 || ((ccnt >> 24) & 0x3) == 0x2) { /* write */
			if (((ccnt >> 26) & 0x3) == 0x3) data = DMA_FLY(io.dma[i]);

			(*write_func)(state, (dst_addr & 0xfffffff), data);

			if (das == 1) dst_addr += min(0xfffffff - (dst_addr & 0xfffffff), 1 << dst);
			else if (das == 2) dst_addr -= min((dst_addr & 0xfffffff), 1 << dst);

			DMA_CDES(io.dma[i]) = dst_addr;
		}

		if (((ccnt >> 26) & 0x3) == 0x3) { /* on-the-fly mode */
			if (((ccnt >> 24) & 0x3) != 0x2) {
				DMA_FLY(io.dma[i]) = data;
				ccnt &= ~0x3000000;
				ccnt |= 0x2000000; /* Read time */
			} else {
				ccnt |= 0x3000000; /* Write time */
			}
		}
	}

	if ((ccnt & 0xfffff) <= (1 << dst)) { /* terminated count */
		ccnt &= ~0xfffff;
		if ((ccnt & 0x200000) == 0x0) ccnt &= ~0x100000; /* clear EN bit */
		DMA_CON(io.dma[i]) &= ~0x30;
		DMA_CON(io.dma[i]) |= 0x20;
		if (((ccnt >> 22) & 0x3) > 1) s3c44b0x_set_interrupt(INT_ZDMA0 - i);
	} else {
		ccnt -= (1 << dst);
		if (((ccnt >> 22) & 0x3) == 2) s3c44b0x_set_interrupt(INT_ZDMA0 - i);
	}

	DMA_CCNT(io.dma[i]) = ccnt;
}


static int s3c44b0x_dma_is_valid(int index)
{
	ARMword ccnt;

	if ((DMA_CON(io.dma[index]) & 0xc) != 0x0) return -1;
	if (((ccnt = DMA_CCNT(io.dma[index])) & 0x100000) == 0x0) return -1;

	if (index < 2) { /* ZDMA */
		if (((ccnt >> 30) & 0x3) < 0x2) return 1; /* DMA request, till now it's impossible in simulation */
	} else { /* BDMA */
		if (((ccnt >> 26) & 0x3) == 0x3) return -1; /* don't support on-the-fly mode */
		if (((ccnt >> 30) & 0x3) != 0x0) return 1; /* DMA request */
	}

	return 0;
}


static void s3c44b0x_dma_do_cycle(ARMul_State *state)
{
	int i;

	for (i = 0; i < 4; i++) {
		if (s3c44b0x_dma_is_valid(i) != 0) continue;
		s3c44b0x_dma_proccess(state, i);
	}
}


static void s3c44b0x_dma_read(ARMword addr, ARMword *data)
{
	s3c44b0x_dma_t *dma = &io.dma[(addr & 0xff) / 0x20 + (addr <= ZDCCNT1 ? 0 : 2)];
	ARMword *val = (ARMword*)dma + (((addr & 0xff) % 0x20) >> 2);

	*data = *val;

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_dma_write(ARMul_State *state, ARMword addr, ARMword data)
{
	s3c44b0x_dma_t *dma = &io.dma[(addr & 0xff) / 0x20 + (addr <= ZDCCNT1 ? 0 : 2)];
	ARMword *val = (ARMword*)dma + (((addr & 0xff) % 0x20) >> 2);

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	if ((addr & 0xff) % 0x20 == 0x00) { /* CON */
		*val = ((*val & 0x30) | (data & ~0x33));
		if ((data & 0x3) == 0x3) DMA_CSRC((*dma)) &= ~0x100000; /* clear EN bit */
		return;
	} else if ((addr & 0xff) % 0x20 < 0x10) { /* ISRC, IDES, ICNT */
		*val = data;
		*(val + 3) = data;
		return;
	}

	PRINT("ERROR: %s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);
}


/* IIS Routine */
static int s3c44b0x_iis_write_to_device(ARMul_State *state, ARMhword *buf, int count)
{
	ARMword data;

	if (buf != s3c44b0x_iisfifo_tx) memcpy(s3c44b0x_iisfifo_tx, buf, count * 2);
	io_write_word(state, IISFIF_TX_CONTROL, ((0xa << 8) | (0x1 << 4) | count));

#if 0
	data = io_read_word(state, IISFIF_TX_CONTROL);
	if ((data & 0xff0) != 0xa20) return -1;
	return (int)(data & 0xf);
#else
	/* don't care */
	return count;
#endif
}


static int s3c44b0x_iis_read_from_device(ARMul_State *state, ARMhword *data)
{
	ARMword tmp;

	tmp = io_read_word(state, IISFIF_RX_CONTROL);
	if (((tmp >> 16) & 0xff) != 0x15) return -1;

	*data = (ARMhword)(tmp & 0xffff);

	return 0;
}


static void s3c44b0x_iis_do_cycle(ARMul_State *state)
{
	int count;

	if ((io.iiscon & 0x1) == 0) return;

	while (((io.iismod >> 7) & 0x1) && (io.iisfifcon & 0x2f0) > 0x200) { /* handling TX FIFO */
		int nWritten = -1;

		if (io.iisfifo_txcnt > 0) {
			io.iisfifo_txcnt -= 1;
			break;
		}

		count = (io.iisfifcon >> 4) & 0xf;
		nWritten = s3c44b0x_iis_write_to_device(state, &io.iisfifo_tx[0], count);

		if (nWritten <= 0) break;
		count -= nWritten;

		io.iisfifcon = ((io.iisfifcon & ~0xf0) | (count << 4));

		if (count == 0) {
			io.iiscon &= ~0x80;
			io.iisfifo_txcnt = 8;
		} else {
			memmove(&io.iisfifo_tx[0], &io.iisfifo_tx[nWritten], count * 2);
		}

		break;
	}

	while (((io.iismod >> 6) & 0x1) && ((io.iisfifcon >> 8) & 0x1)) { /* handling RX FIFO */
		ARMhword tmp;

		if ((count = io.iisfifcon & 0xf) >= 8) break;
		if (s3c44b0x_iis_read_from_device(state, &tmp) != 0) break;

		io.iisfifo_rx[count++] = tmp;
		io.iisfifcon = ((io.iisfifcon & ~0xf) | count);
		if (count == 8) io.iiscon &= ~0x40;

		break;
	}

	while ((io.iiscon & 0x30) != 0) { /* BDMA request */
		int rx_empty = ((io.iisfifcon & 0x100) ? ((io.iisfifcon & 0xf) == 0) : 0);
		int tx_ready = ((io.iisfifcon & 0x100) ? (((io.iisfifcon >> 4) & 0xf) < 8) : 1);
		ARMword mask = 0;

		if (s3c44b0x_dma_is_valid(2) != 1) break;
		if (((DMA_CCNT(io.dma[2]) >> 30) & 0x3) != 0x1) break;

		if ((DMA_CDES(io.dma[2]) & 0xfffffff) == IISFIF + state->bigendSig * 2 && tx_ready) mask |= (0x1 << 5);
		if ((DMA_CSRC(io.dma[2]) & 0xfffffff) == IISFIF + state->bigendSig * 2 && !rx_empty) mask |= (0x1 << 4);
		if ((io.iiscon & mask) != 0) s3c44b0x_dma_proccess(state, 2);

		break;
	}
}


static void s3c44b0x_iis_read(ARMul_State *state, ARMword addr, ARMword *data)
{
	switch (addr) {
		case IISCON:
			*data = io.iiscon;
			break;

		case IISMOD:
			*data = io.iismod;
			break;

		case IISPSR:
			*data = io.iispsr;
			break;

		case IISFIFCON:
			*data = io.iisfifcon;
			break;

		case IISFIF:
			if (!((io.iiscon & 0x1) && ((io.iismod >> 6) & 0x1))) break;
			if ((io.iisfifcon & 0x100) != 0) { /* FIFO */
				int count = (io.iisfifcon & 0xf);
				if (count > 0) {
					*data = io.iisfifo_rx[0];
					io.iisfifcon = ((io.iisfifcon & ~0xf) | (--count));
					if (count > 0) memmove(&io.iisfifo_rx[0], &io.iisfifo_rx[1], count * 2);
					io.iiscon |= 0x40;
				}
			} else { /* non FIFO */
				ARMhword tmp;
				if (s3c44b0x_iis_read_from_device(state, &tmp) == 0) *data = tmp;
			}
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c44b0x_iis_write(ARMul_State *state, ARMword addr, ARMword data)
{
	ARMhword tmp, count;

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case IISCON:
			io.iiscon = ((io.iiscon & 0x1c0) | (data & ~0x1c0));
			break;

		case IISMOD:
			io.iismod  = data;
			break;

		case IISPSR:
			io.iispsr = data;
			break;

		case IISFIFCON:
			io.iisfifcon = ((io.iisfifcon & 0xff) | (data & ~0xff));
			break;

		case IISFIF:
			if (!((io.iiscon & 0x1) && ((io.iismod >> 7) & 0x1))) break;
			tmp = data & 0xffff;
			if ((io.iisfifcon & 0x200) != 0) { /* FIFO */
				if ((count = ((io.iisfifcon >> 4) & 0xf)) < 8) {
					io.iisfifo_tx[count++] = tmp;
					io.iisfifcon = ((io.iisfifcon & ~0xf0) | (count << 4));
					io.iiscon |= 0x80;
				}
			} else { /* non FIFO */
				s3c44b0x_iis_write_to_device(state, &tmp, 1);
			}
			break;

		default:
			break;
	}
}


/* IO Read Routine */
static ARMword s3c44b0x_io_read_word(ARMul_State *state, ARMword addr)
{
	ARMword data = -1;

	/* Interrupt */
	if (addr >= INTCON && addr <= F_ISPC) {
		s3c44b0x_interrupt_read(addr, &data);
		return data;
	}

	/* UART */
	if (addr >= ULCON0 && addr <= UBRDIV1) {
		s3c44b0x_uart_read(addr, &data);
		return data;
	}

	/* Timer */
	if ((addr >= WTCON && addr <= WTCNT) || (addr >= TCFG0 && addr <= TCNTO5)) {
		s3c44b0x_timer_read(addr, &data);
		return data;
	}

	/* I/O Ports */
	if (addr >= PCONA && addr <= EXTINTPND) {
		s3c44b0x_ports_read(addr, &data);
		return data;
	}

	/* RTC */
	if (addr >= RTCCON && addr <= TICINT) {
		s3c44b0x_rtc_read(addr, &data);
		return data;
	}

	/* DMA */
	if ((addr >= ZDCON0 && addr <= ZDCCNT1) || (addr >= BDCON0 && addr <= BDCCNT1)) {
		s3c44b0x_dma_read(addr, &data);
		return data;
	}

	/* IIS */
	if (addr >= IISCON && addr <= IISFIF) {
		s3c44b0x_iis_read(state, addr, &data);
		return data;
	}

	/* TODO */
	switch (addr) {
		case SYSCFG:
			data = 0x01; /* FIXME */
			break;

		case NCACHBE0:
			data = io.ncachbe0;
			break;

		case NCACHBE1:
			data = io.ncachbe1;
			break;

		case SBUSCON:
			data = io.sbuscon;
			break;

		case BWSCON:
			data = io.bwscon;
			break;

		default:
			DEBUG("UNIMPLEMENTED: %s(addr:0x%08x)\n", __FUNCTION__, addr);
			break;
	}

	return data;
}


static ARMword s3c44b0x_io_read_byte(ARMul_State *state, ARMword addr)
{
	ARMword data, offset;

	data = s3c44b0x_io_read_word(state, (addr & ~0x3));

	/* bit offset into the word */
	offset = ((state->bigendSig * 3) ^ (addr & 3)) << 3;

	return ((data >> offset) & 0xff);
}


static ARMword s3c44b0x_io_read_halfword(ARMul_State *state, ARMword addr)
{
	ARMword data, offset;

	data = s3c44b0x_io_read_word(state, addr & ~0x3);

	/* bit offset into the word */
	offset = ((state->bigendSig * 2) ^ (addr & 2)) << 3;

	return ((data >> offset) & 0xffff);
}


/* IO Write Routine */
static void s3c44b0x_io_write_word(ARMul_State *state, ARMword addr, ARMword data)
{
	/* Interrupt */
	if (addr >= INTCON && addr <= F_ISPC) {
		s3c44b0x_interrupt_write(state, addr, data);
		return;
	}

	/* UART */
	if (addr >= ULCON0 && addr <= UBRDIV1) {
		s3c44b0x_uart_write(state, addr, data);
		return;
	}

	/* Timer */
	if ((addr >= WTCON && addr <= WTCNT) || (addr >= TCFG0 && addr <= TCNTO5)) {
		s3c44b0x_timer_write(state, addr, data);
		return;
	}

	/* I/O Ports */
	if (addr >= PCONA && addr <= EXTINTPND) {
		s3c44b0x_ports_write(state, addr, data);
		return;
	}

	/* RTC */
	if (addr >= RTCCON && addr <= TICINT) {
		s3c44b0x_rtc_write(state, addr, data);
		return;
	}

	/* DMA */
	if ((addr >= ZDCON0 && addr <= ZDCCNT1) || (addr >= BDCON0 && addr <= BDCCNT1)) {
		s3c44b0x_dma_write(state, addr, data);
		return;
	}

	/* IIS */
	if (addr >= IISCON && addr <= IISFIF) {
		s3c44b0x_iis_write(state, addr, data);
		return;
	}

	/* TODO */
	switch (addr) {
		case SYSCFG:
			io.syscfg = data;
			break;

		case NCACHBE0:
			io.ncachbe0 = data;
			break;

		case NCACHBE1:
			io.ncachbe1 = data;
			break;

		case SBUSCON:
			io.sbuscon = data;
			break;

		case BWSCON:
			io.bwscon = (io.bwscon & 0x1) | (data & ~0x1);
			break;

		default:
			DEBUG("UNIMPLEMENTED: %s(addr:0x%08x, data:0x%x)\n", __FUNCTION__, addr, data);
			break;
	}
}


static void s3c44b0x_io_write_byte(ARMul_State *state, ARMword addr, ARMword data)
{
	if ((state->bigendSig * 3) == (addr & 3)) {
		s3c44b0x_io_write_word(state, addr & ~0x3, data);
		return;
	}

	DEBUG("ERROR: %s(addr:0x%08x, data:0x%x)\n", __FUNCTION__, addr, data);
}


static void s3c44b0x_io_write_halfword(ARMul_State *state, ARMword addr, ARMword data)
{
	if ((state->bigendSig * 2) == (addr & 3)) {
		s3c44b0x_io_write_word(state, addr & ~0x3, data);
		return;
	}

	DEBUG("ERROR: %s(addr:0x%08x, data:0x%x)\n", __FUNCTION__, addr, data);
}


static void s3c44b0x_io_do_cycle(ARMul_State *state)
{
	/* TODO */
	s3c44b0x_uart_do_cycle(state);
	s3c44b0x_timer_do_cycle(state);
	s3c44b0x_rtc_do_cycle(state);
	s3c44b0x_dma_do_cycle(state);
	s3c44b0x_iis_do_cycle(state);
	s3c44b0x_update_int(state);
}


/* Machine Initialization */
#define MACH_IO_DO_CYCLE_FUNC(f)	((void (*)(void*))(f))
#define MACH_IO_RESET_FUNC(f)		((void (*)(void*))(f))
#define MACH_IO_READ_FUNC(f)		((uint32_t (*)(void*, uint32_t))(f))
#define MACH_IO_WRITE_FUNC(f)		((void (*)(void*, uint32_t, uint32_t))(f))
#define MACH_IO_UPDATE_INT_FUNC(f)	((void (*)(void*))(f))
#define MACH_IO_SET_INTR_FUNC(f)	((void (*)(u32))(f))
#define MACH_IO_PENDING_INTR_FUNC(f)	((int (*)(u32))(f))
#define MACH_IO_UPDATE_INTR_FUNC(f)	((void (*)(void*))(f))

void s3c44b0x_mach_init(ARMul_State *state, machine_config_t *this_mach)
{
	ARMul_SelectProcessor(state, ARM_v4_Prop);
	state->lateabtSig = HIGH;

	state->Reg[1] = 178; /* R1: machine type : found in linux-2.6.x/include/asm/mach-types.h */

	this_mach->mach_io_do_cycle = MACH_IO_DO_CYCLE_FUNC(s3c44b0x_io_do_cycle);
	this_mach->mach_io_reset = MACH_IO_RESET_FUNC(s3c44b0x_io_reset);

	this_mach->mach_io_read_word = MACH_IO_READ_FUNC(s3c44b0x_io_read_word);
	this_mach->mach_io_read_halfword = MACH_IO_READ_FUNC(s3c44b0x_io_read_halfword);
	this_mach->mach_io_read_byte = MACH_IO_READ_FUNC(s3c44b0x_io_read_byte);
	this_mach->mach_io_write_word = MACH_IO_WRITE_FUNC(s3c44b0x_io_write_word);
	this_mach->mach_io_write_halfword = MACH_IO_WRITE_FUNC(s3c44b0x_io_write_halfword);
	this_mach->mach_io_write_byte = MACH_IO_WRITE_FUNC(s3c44b0x_io_write_byte);

	this_mach->mach_update_int = MACH_IO_UPDATE_INT_FUNC(s3c44b0x_update_int);

	/* mach_set_intr, mach_pending_intr, mach_update_intr, state : for devices, such as NET,LCD etc. */
	this_mach->mach_set_intr = MACH_IO_SET_INTR_FUNC(s3c44b0x_set_interrupt);
	this_mach->mach_pending_intr = MACH_IO_PENDING_INTR_FUNC(s3c44b0x_pending_intr);
	this_mach->mach_update_intr = MACH_IO_UPDATE_INTR_FUNC(s3c44b0x_update_intr);
	this_mach->state = (void*)state;
}


