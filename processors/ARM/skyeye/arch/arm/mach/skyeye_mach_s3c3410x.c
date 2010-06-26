/*
	skyeye_mach_s3c3410x.c - SAMSUNG's S3C3410X simulation for skyeye
	Copyright (C) 2007 Skyeye Develop Group
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
 * 03/04/2007	Written by Anthony Lee
 */

/*
 * COMPLETED: Interrupt, WatchDog, Timer, UART, DMA
 * UNIMPLEMENTED: I/O Port, etc.
 */

#include "armdefs.h"
#include "armemu.h"
#include "s3c3410x.h"
#include "skyeye_uart.h"

#define S3C3410X_DEBUG			0

#define PRINT(x...)			printf("[S3C3410X]: " x)

#if S3C3410X_DEBUG
#define DEBUG(x...)			printf("[S3C3410X]: " x)
#else
#define DEBUG(x...)			(void)0
#endif

/*
 * CYCLE_TIMES_PER_SECOND:
 * 	It's near 40000 times on my machine,
 * 	you can change the value to fit your machine.
 */
#define CYCLE_TIMES_PER_SECOND		(40000)

#define MCLK				(40) /* MHz */
#define TIMER_COUNT_UP_PER_SECOND	(1000000 * MCLK) /* prescale=1, divider=1 */
#define TIMER_COUNT_UP_PER_CYCLE	(TIMER_COUNT_UP_PER_SECOND / CYCLE_TIMES_PER_SECOND)

struct s3c3410x_timer_t {
	ARMword tdat;
	ARMword tpre;
	ARMword tcon;
	ARMword tcnt;
	ARMword tcnt_scaler;
};

struct s3c3410x_dma_t {
	ARMword con;
	ARMword src;
	ARMword dst;
	ARMword cnt;
};

/* S3C3410X Internal IO Registers */
struct s3c3410x_io_t
{
	/* System Registers */
	ARMword syscfg;
	ARMword syscon;

	/* Interrupt Controller Registers */
	ARMword intmod;
	ARMword intpnd;
	ARMword intmsk;
	ARMword intpri[8];

	/* Timer Registers */
	ARMword btcon;
	ARMword btcnt;
	ARMword btcnt_scaler;
	struct s3c3410x_timer_t timer[5];
	ARMword tfcon;
	ARMword tfstat;
	uint64_t tf4;
	ARMword tf4_repeat[2];

	/* UART Registers */
	ARMword ulcon;
	ARMword ucon;
	ARMword ustat;
	ARMword ufcon;
	ARMword ufstat;
	ARMword urxh;
	ARMword ubrdiv;

	/* DMA Registers */
	struct s3c3410x_dma_t dma[2];
};

static struct s3c3410x_io_t s3c3410x_io;
#define io s3c3410x_io

extern ARMword mem_read_byte(ARMul_State*, ARMword);
extern ARMword mem_read_halfword(ARMul_State*, ARMword);
extern ARMword mem_read_word(ARMul_State*, ARMword);
extern void mem_write_byte(ARMul_State*, ARMword, ARMword);
extern void mem_write_halfword(ARMul_State*, ARMword, ARMword);
extern void mem_write_word(ARMul_State*, ARMword, ARMword);

static int s3c3410x_dma_is_valid(int index);
static void s3c3410x_dma_proccess(ARMul_State *state, int index);


static void s3c3410x_io_reset(ARMul_State *state)
{
	int i;

	memset(&io, 0, sizeof(io));

	/* System */
	io.syscfg = 0xfff1;

	/* Interrupt */
	io.intpri[0] = 0x03020100;
	io.intpri[1] = 0x07060504;
	io.intpri[2] = 0x0b0a0908;
	io.intpri[3] = 0x0f0e0d0c;
	io.intpri[4] = 0x13121110;
	io.intpri[5] = 0x17161514;
	io.intpri[6] = 0x1b1a1918;
	io.intpri[7] = 0x1f1e1d1c;

	/* Timer */
	for (i = 0; i < 5; i++) io.timer[i].tpre = 0xff;
	for (i = 0; i < 3; i++) io.timer[i].tdat = 0xffff;
	for (i = 3; i < 5; i++) io.timer[i].tdat = 0xff;

	/* UART */
	io.ustat = 0xc0;
}


/* Interrupt Routine */
static void s3c3410x_update_int(ARMul_State *state)
{
	ARMword requests = (io.syscon & 0x40) ? (io.intpnd & io.intmsk) : 0x0;

	state->NfiqSig = (requests & io.intmod) ? LOW : HIGH;
	state->NirqSig = (requests & ~io.intmod) ? LOW : HIGH;
}


static void s3c3410x_set_interrupt(unsigned int irq)
{
	io.intpnd |= (0x1 << irq);
}


static void s3c3410x_interrupt_read(ARMword addr, ARMword *data)
{
	switch (addr) {
		case INTMOD:
			*data = io.intmod;
			break;

		case INTPND:
			*data = io.intpnd;
			break;

		case INTMSK:
			*data = io.intmsk;
			break;

		case INTPRI0:
		case INTPRI1:
		case INTPRI2:
		case INTPRI3:
		case INTPRI4:
		case INTPRI5:
		case INTPRI6:
		case INTPRI7:
			*data = io.intpri[(addr - INTPRI0) / 0x4];
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c3410x_interrupt_write(ARMul_State *state, ARMword addr, ARMword data)
{
	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case INTMOD:
			io.intmod = data;
			break;

		case INTPND:
			io.intpnd &= data;
			break;

		case INTMSK:
			io.intmsk = data;
			break;

		case INTPRI0:
		case INTPRI1:
		case INTPRI2:
		case INTPRI3:
		case INTPRI4:
		case INTPRI5:
		case INTPRI6:
		case INTPRI7:
			io.intpri[(addr - INTPRI0) / 0x4] = data;
			break;

		default:
			break;
	}
}


/* Timer Routine */
static void s3c3410x_timer_do_cycle(ARMul_State *state)
{
	int i, k;
	ARMword tdat, count, empty_count;
	ARMword cnt_up, cnt_divider, cnt_clock_divider = 1;

#if 0
	switch ((io.syscon >> 3) & 0x7) {
		case 0: cnt_clock_divider = 16; break;
		case 1: cnt_clock_divider = 8; break;
		case 2: cnt_clock_divider = 2; break;
		case 4: cnt_clock_divider = 1024; break;
		default: break;
	}
#endif

	for (i = 0; i < 5; i++) {
		if ((io.timer[i].tcon & 0x80) == 0) continue;

		if (i < 4 || (io.tfcon & 0x1) == 0) {
			tdat = io.timer[i].tdat;
		} else {
			if ((count = (io.tfstat & 0x7)) == 0) break;
			if (io.timer[4].tcnt == (tdat = (io.tf4 & 0xff))) {
				if (io.tf4_repeat[0] == 0) {
					io.tf4_repeat[0] = io.tf4_repeat[1];
					if ((empty_count = ((io.tfcon >> 2) & 0x3)) > 0) {
						if (empty_count == 3) empty_count = 4;
						if (io.tfstat & 0x8) count++;
						io.tfstat = count - min(empty_count, count);
						io.tf4 >>= (empty_count << 3);
					}
					s3c3410x_set_interrupt(INT_TF);
				} else {
					io.tf4_repeat[0] -= 1;
				}
			}
		}

		cnt_divider = cnt_clock_divider * (io.timer[i].tpre + 1) << (i < 3 ? 0 : (1 << (4 - (io.timer[i].tcon & 0x3))));
		cnt_up = TIMER_COUNT_UP_PER_CYCLE / cnt_divider;
		if (cnt_up == 0) {
			if (io.timer[i].tcnt_scaler == 0) {
				io.timer[i].tcnt_scaler = cnt_divider / TIMER_COUNT_UP_PER_CYCLE;
				continue;
			} else if ((io.timer[i].tcnt_scaler -= 1) != 0) {
				continue;
			}
			cnt_up = 1;
		}

		switch ((io.timer[i].tcon >> 3) & 0x7) {
			case 0: /* Interval Mode */
				if (io.timer[i].tcnt == tdat) {
					s3c3410x_set_interrupt(INT_TMC0 + i * 2);
					io.timer[i].tcnt = 0;
					break;
				}
				if (io.timer[i].tcnt > tdat) break;
				io.timer[i].tcnt += min(tdat - io.timer[i].tcnt, cnt_up);
				break;

			case 1: /* Match & overflow mode (Timer0/1/2), PWM mode (Timer3/4) */
				if (io.timer[i].tcnt == tdat) {
					s3c3410x_set_interrupt(INT_TMC0 + i * 2);
				}
				if (io.timer[i].tcnt == (i < 3 ? 0xffff : 0xff)) {
					s3c3410x_set_interrupt(INT_TOF0 + i * 2);
					io.timer[i].tcnt = 0;
					break;
				}
				io.timer[i].tcnt += min((io.timer[i].tcnt < tdat ? tdat :
										   (i < 3 ? 0xffff : 0xff)) -
							io.timer[i].tcnt, cnt_up);
				break;

			case 2: /* Match & DMA mode */
				if (!(i == 1 || i == 3)) break;
				for (k = 0; k < 2; k++) {
					if (s3c3410x_dma_is_valid(k) != 1) continue;
					if (((io.dma[k].con >> 2) & 0x3) != 0x3) continue;
					if (i == 1 && io.dma[k].dst == TDAT1) break;
					if (i == 3 && io.dma[k].dst == TDAT3) break;
				}
				if (k == 2) break;
				if (io.timer[i].tcnt == tdat) {
					s3c3410x_set_interrupt(INT_TMC0 + i * 2);
					io.timer[i].tcnt = 0;
					s3c3410x_dma_proccess(state, k);
					break;
				}
				if (io.timer[i].tcnt > tdat) break;
				io.timer[i].tcnt += min(tdat - io.timer[i].tcnt, cnt_up);
				break;

			default: /* Other mode unimplemented yet */
				break;
		}
	}

	/* Basic Timer and WatchDog */
	cnt_divider = 1 << (13 - ((io.btcon >> 2) & 0x3));
	cnt_up = TIMER_COUNT_UP_PER_CYCLE / cnt_divider;
	if (cnt_up == 0) {
		if (io.btcnt_scaler == 0) {
			io.btcnt_scaler = cnt_divider / TIMER_COUNT_UP_PER_CYCLE;
			goto next;
		} else if ((io.btcnt_scaler -= 1) != 0) {
			goto next;
		}
		cnt_up = 1;
	}

	if (io.btcnt == 0xff) {
		io.btcnt = 0;
		s3c3410x_set_interrupt(INT_BT);
	} else {
		io.btcnt += min(0xff - io.btcnt, cnt_up);
	}

	if (io.btcon & 0x10000) {
		ARMword wdt = (io.btcon >> 8) & 0xff;
		if (wdt == 0xff) { /* asserts reset signal */
			state->NresetSig = LOW;
			PRINT("****************** WATCHDOG RESET ******************\n");
		} else {
			io.btcon = (io.btcon & ~0xff00) | ((wdt + min(0xff - wdt, cnt_up)) << 8);
		}
	}

next:
	return;
}


static void s3c3410x_timer_read(ARMword offset, ARMword *data, int index)
{
	switch (offset) {
		case 0: /* TDAT */
			*data = io.timer[index].tdat;
			break;

		case 2: /* TPRE */
			*data = io.timer[index].tpre;
			break;

		case 3: /* TCON */
			*data = io.timer[index].tcon;
			break;

		case 6: /* TCNT */
			*data = io.timer[index].tcnt;
			break;

		case 0x8: /* TFW4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat == 0) break;
			*data = io.tf4 & 0xffffffff;
			io.tf4 >>= 32;
			io.tfstat = (io.tfstat < 7 ? (io.tfstat - min(io.tfstat, 4)) : (io.tfstat & ~0x8));
			break;

		case 0xa: /* TFHW4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat == 0) break;
			*data = io.tf4 & 0xffff;
			io.tf4 >>= 16;
			io.tfstat = (io.tfstat < 7 ? (io.tfstat - min(io.tfstat, 2)) : (io.tfstat & ~0x8));
			break;

		case 0xb: /* TFB4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat == 0) break;
			*data = io.tf4 & 0xff;
			io.tf4 >>= 8;
			io.tfstat = (io.tfstat < 7 ? (io.tfstat - 1) : (io.tfstat & ~0x8));
			break;

		case 0xe: /* TFSTAT */
			if (index == 4) *data = io.tfstat;
			break;

		case 0xf: /* TFCON */
			if (index == 4) *data = io.tfcon;
			break;

		default:
			break;
	}

	DEBUG("%s(Timer%d, offset:0x%x, data:0x%x)\n", __FUNCTION__, index, offset, *data);
}


static void s3c3410x_timer_write(ARMul_State *state, ARMword offset, ARMword data, int index)
{
	DEBUG("%s(Timer%d, offset:0x%x, data:0x%x)\n", __FUNCTION__, index, offset, data);

	switch (offset) {
		case 0: /* TDAT */
			io.timer[index].tdat = min(data, (index < 3 ? 0xffff : 0xff));
			break;

		case 2: /* TPRE */
			io.timer[index].tpre = min(data, 0xff);
			break;

		case 3: /* TCON */
			io.timer[index].tcon = min((data & ~0x40), 0xff);
			if (data & 0x40) io.timer[index].tcnt = 0;
			break;

		case 0x8: /* TFW4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat > 7) break;
			io.tf4 &= ~(((uint64_t)0xffffffff) << (io.tfstat << 3));
			io.tf4 |= (((uint64_t)data) << (io.tfstat << 3));
			io.tfstat += (io.tfstat < 4 ? 4 : 8);
			break;

		case 0xa: /* TFHW4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat > 7) break;
			io.tf4 &= ~(((uint64_t)0xffff) << (io.tfstat << 3));
			io.tf4 |= (((uint64_t)min(data, 0xffff)) << (io.tfstat << 3));
			io.tfstat += (io.tfstat < 6 ? 2 : 8);
			break;

		case 0xb: /* TFB4 */
			if (index != 4) break;
			if ((io.tfcon & 0x1) == 0 || io.tfstat > 7) break;
			io.tf4 &= ~(((uint64_t)0xff) << (io.tfstat << 3));
			io.tf4 |= (((uint64_t)min(data, 0xff)) << (io.tfstat << 3));
			io.tfstat += (io.tfstat < 7 ? 1 : 8);
			break;

		case 0xf: /* TFCON */
			if (index == 4) {
				io.tfcon = min((data & ~0x2), 0xff);
				if (data & 0x2) io.tfstat = 0;
				if (data & 0x1) {
					io.tf4_repeat[1] = (1 << ((data >> 4) & 0x3)) - 1;
					io.tf4_repeat[0] = io.tf4_repeat[1];
				}
			}
			break;

		default:
			break;
	}
}


/* UART Routine */
static void s3c3410x_uart_do_cycle(ARMul_State *state)
{
	int i;
	unsigned char buf;
	struct timeval tv;

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	if ((io.ustat & 0x20) == 0 && (io.ucon & 0x3) != 0) {
		if (skyeye_uart_read(-1, &buf, 1, &tv, NULL) > 0) {
			io.urxh = buf;
			io.ustat |= 0x20;
			io.ufstat = (io.ufstat & ~0x7) | 0x1;
			if ((io.ucon & 0x3) == 0x1) s3c3410x_set_interrupt(INT_URX);
		}
	}

	for (i = 0; i < 2; i++) { /* DMA request */
		if ((io.ucon & 0x3) == 0x2 + i || (io.ucon & 0xc) == 0x8 + i) {
			int rx_empty = ((io.ucon & 0x3) != 0x0 ? ((io.ustat & 0x20) == 0) : 1);
			int tx_ready = ((io.ucon & 0xc) != 0x0 ? 1 : 0);
			ARMword mask = 0;

			do {
				if (s3c3410x_dma_is_valid(i) != 1) break;
				if (((io.dma[i].con >> 2) & 0x3) != 0x2) break;

				if ((io.dma[i].dst == UTXH ||
				     io.dma[i].dst == UTXH_HW ||
				     io.dma[i].dst == UTXH_W) && tx_ready) mask |= 0x2 + i;
				if ((io.dma[i].src == URXH ||
				     io.dma[i].src == URXH_HW ||
				     io.dma[i].src == URXH_W) && !rx_empty) mask |= 0x8 + i;
				if ((io.ucon & mask) != 0) s3c3410x_dma_proccess(state, i);
			} while (0);
		}
	}
}


static void s3c3410x_uart_read(ARMword addr, ARMword *data)
{
	switch (addr) {
		case ULCON:
			*data = io.ulcon;
			break;

		case UCON:
			*data = io.ucon;
			break;

		case USTAT:
			*data = io.ustat;
			break;

		case UFCON:
			*data = io.ufcon;
			break;

		case UFSTAT:
			*data = io.ufstat;
			break;

		case URXH_W:
		case URXH_HW:
		case URXH:
			*data = io.urxh;
			io.ustat &= ~0x20;
			io.ufstat &= ~0x7;
			break;

		case UBRDIV:
			*data = io.ubrdiv;
			break;

		default:
			break;
	}

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, *data);
}


static void s3c3410x_uart_write(ARMul_State *state, ARMword addr, ARMword data)
{
	int cnt = 0;

	DEBUG("%s(addr:0x%x, data:0x%x)\n", __FUNCTION__, addr, data);

	switch (addr) {
		case ULCON:
			io.ulcon = data;
			break;

		case UCON:
			io.ucon = data;
			break;

		case UFCON:
			io.ufcon = data;
			break;

		case UTXH_W:
			cnt = 4;
			break;
		case UTXH_HW:
			cnt = 2;
			break;
		case UTXH:
			cnt = 1;
			break;

		case UBRDIV:
			io.ubrdiv = data;
			break;

		default:
			break;
	}

	if (cnt > 0 && (io.ucon & 0xc)) {
		do {
			char tmp = data & 0xff;
			data >>= 8;
			skyeye_uart_write(-1, (void*)&tmp, 1, NULL);
		} while (--cnt > 0);

		if ((io.ucon & 0xc) == 0x4) s3c3410x_set_interrupt(INT_UTX);
	}
}


/* DMA Routine */
static int s3c3410x_dma_is_valid(int index)
{
	if (!(io.dma[index].con & 0x1)) return -1;
	if (io.dma[index].cnt == 0) return -1;

	if (((io.dma[index].con >> 2) & 0x3) == 0x1) return -1;
	if (((io.dma[index].con >> 2) & 0x3) != 0x0) return 1;

	return 0;
}


static void s3c3410x_dma_proccess(ARMul_State *state, int index)
{
	ARMword data, bytes, n = 0;

	if (io.dma[index].cnt == 0) return;

	io.dma[index].con |= 0x2;

restart:
	switch ((bytes = (1 << ((io.dma[index].con >> 12) & 0x3)))) {
		case 1:
			//data = mem_read_byte(state, io.dma[index].src);
			bus_read(8, io.dma[index].src, &data);
			//mem_write_byte(state, io.dma[index].dst, data);
			bus_write(8, io.dma[index].dst, data);
			break;

		case 2:
			//data = mem_read_halfword(state, io.dma[index].src);
			bus_read(16, io.dma[index].src, &data);
			//mem_write_halfword(state, io.dma[index].dst, data);			
			bus_write(16, io.dma[index].dst, data);
			break;

		case 4:
			//data = mem_read_word(state, io.dma[index].src);
			bus_read(32, io.dma[index].src, &data);
			//mem_write_word(state, io.dma[index].dst, data);
			bus_write(32, io.dma[index].dst, data);
			break;

		default:
			return;
	}

	if (!((io.dma[index].con >> 7) & 0x1)) {
		if (((io.dma[index].con >> 5) & 0x1) && io.dma[index].src >= bytes)
			io.dma[index].src -= bytes;
		else if (io.dma[index].src <= 0xffffffe - bytes)
			io.dma[index].src++;
	}

	if (!((io.dma[index].con >> 6) & 0x1)) {
		if (((io.dma[index].con >> 4) & 0x1) && io.dma[index].dst >= bytes)
			io.dma[index].dst -= bytes;
		else if (io.dma[index].dst <= 0xffffffe - bytes)
			io.dma[index].dst++;
	}

	if (((io.dma[index].con >> 9) & 0x1) && ++n < 4) goto restart;

	io.dma[index].cnt -= 1;
	if (io.dma[index].cnt != 0 && ((io.dma[index].con >> 14) & 0x1)) {
		if (((io.dma[index].con >> 2) & 0x3) == 0x0) {
			n = 0;
			goto restart;
		}
	}
	if (io.dma[index].cnt == 0) {
		io.dma[index].con &= ~0x3;
		s3c3410x_set_interrupt(INT_DMA0 + index);
	}
}


static void s3c3410x_dma_do_cycle(ARMul_State *state)
{
	int i;

	for (i = 0; i < 2; i++) {
		if (s3c3410x_dma_is_valid(i) != 0) continue;
		s3c3410x_dma_proccess(state, i);
	}
}


static void s3c3410x_dma_read(ARMword offset, ARMword *data, int index)
{
	switch (offset) {
		case 0x0: /* DMASRC */
			*data = io.dma[index].src;
			break;

		case 0x4: /* DMADST */
			*data = io.dma[index].dst;
			break;

		case 0x8: /* DMACNT */
			*data = io.dma[index].cnt;
			break;

		case 0xc: /* DMACON */
			*data = io.dma[index].con;
			break;

		default:
			break;
	}

	DEBUG("%s(DMA%d, offset:0x%x, data:0x%x)\n", __FUNCTION__, index, offset, *data);
}


static void s3c3410x_dma_write(ARMul_State *state, ARMword offset, ARMword data, int index)
{
	DEBUG("%s(DMA%d, offset:0x%x, data:0x%x)\n", __FUNCTION__, index, offset, data);

	switch (offset) {
		case 0x0: /* DMASRC */
			io.dma[index].src = (data & 0xffffffe);
			break;

		case 0x4: /* DMADST */
			io.dma[index].dst = (data & 0xffffffe);
			break;

		case 0x8: /* DMACNT */
			io.dma[index].cnt = (data & 0x7ffffff);
			break;

		case 0xc: /* DMACON */
			io.dma[index].con = (io.dma[index].con & 0x2) | (data & ~0x2);
			if ((data & 0x1) == 0) { /* stop */
				io.dma[index].con &= ~0x2;
				if (data & 0x100) s3c3410x_set_interrupt(INT_DMA0 + index);
			}
			break;

		default:
			break;
	}
}


/* IO Read Routine */
static ARMword s3c3410x_io_read_word(ARMul_State *state, ARMword addr)
{
	ARMword data = -1;

	/* Interrupt */
	if (addr >= INTMOD && addr <= INTPRI7) {
		s3c3410x_interrupt_read(addr, &data);
		return data;
	}

	/* Timer */
	if (addr >= TDAT0 && addr <= TFW4) {
		s3c3410x_timer_read(addr & 0xf, &data, (addr >> 4) & 0xf);
		return data;
	} else if (addr == BTCON) {
		return (io.btcon & 0xffff);
	} else if (addr == BTCNT) {
		return io.btcnt;
	}

	/* UART */
	if (addr >= ULCON && addr <= UBRDIV) {
		s3c3410x_uart_read(addr, &data);
		return data;
	}

	/* DMA */
	if (addr >= DMASRC0 && addr <= DMACON1 && (addr & 0xfff) <= 0xc) {
		s3c3410x_dma_read(addr & 0xf, &data, ((addr >> 12) & 0xf) - 3);
		return data;
	}

	switch (addr) {
		case SYSCFG:
			data = io.syscfg;
			break;

		case SYSCON:
			data = io.syscon;
			break;

		default:
			DEBUG("UNIMPLEMENTED: %s(addr:0x%08x)\n", __FUNCTION__, addr);
			break;
	}

	return data;
}


static ARMword s3c3410x_io_read_byte(ARMul_State *state, ARMword addr)
{
	return s3c3410x_io_read_word(state, addr);
}


static ARMword s3c3410x_io_read_halfword(ARMul_State *state, ARMword addr)
{
	return s3c3410x_io_read_word(state, addr);
}


/* IO Write Routine */
static void s3c3410x_io_write_word(ARMul_State *state, ARMword addr, ARMword data)
{
	/* Interrupt */
	if (addr >= INTMOD && addr <= INTPRI7) {
		s3c3410x_interrupt_write(state, addr, data);
		return;
	}

	/* Timer */
	if (addr >= TDAT0 && addr <= TFW4) {
		s3c3410x_timer_write(state, addr & 0xf, data, (addr >> 4) & 0xf);
		return;
	} else if (addr == BTCON) {
		io.btcon &= ~0xffff;
		io.btcon |= (data & ~0x1ff03);
		if (((data >> 8) & 0xff) == 0xa5) io.btcon &= ~0x10000;
		else if ((data & 0x1) == 0) io.btcon |= ((data & 0xff00) | 0x10000);
		if (data & 0x2) io.btcnt = 0;
		return;
	}

	/* UART */
	if (addr >= ULCON && addr <= UBRDIV) {
		s3c3410x_uart_write(state, addr, data);
		return;
	}

	/* DMA */
	if (addr >= DMASRC0 && addr <= DMACON1 && (addr & 0xfff) <= 0xc) {
		s3c3410x_dma_write(state, addr & 0xf, data, ((addr >> 12) & 0xf) - 3);
		return;
	}

	switch (addr) {
		case SYSCFG:
			io.syscfg = data;
			break;

		case SYSCON:
			io.syscon = data;
			break;

		default:
			DEBUG("UNIMPLEMENTED: %s(addr:0x%08x, data:0x%x)\n", __FUNCTION__, addr, data);
			break;
	}
}


static void s3c3410x_io_write_byte(ARMul_State *state, ARMword addr, ARMword data)
{
	s3c3410x_io_write_word(state, addr, data);
}


static void s3c3410x_io_write_halfword(ARMul_State *state, ARMword addr, ARMword data)
{
	s3c3410x_io_write_word(state, addr, data);
}


static void s3c3410x_io_do_cycle(ARMul_State *state)
{
	s3c3410x_timer_do_cycle(state);
	s3c3410x_uart_do_cycle(state);
	s3c3410x_dma_do_cycle(state);
	s3c3410x_update_int(state);
}


/* Machine Initialization */
#define MACH_IO_DO_CYCLE_FUNC(f)	((void (*)(void*))(f))
#define MACH_IO_RESET_FUNC(f)		((void (*)(void*))(f))
#define MACH_IO_READ_FUNC(f)		((uint32_t (*)(void*, uint32_t))(f))
#define MACH_IO_WRITE_FUNC(f)		((void (*)(void*, uint32_t, uint32_t))(f))
#define MACH_IO_UPDATE_INT_FUNC(f)	((void (*)(void*))(f))

void s3c3410x_mach_init(ARMul_State *state, machine_config_t *this_mach)
{
	if (state->bigendSig != HIGH) {
		PRINT("*** ERROR: Only support big endian, maybe you need to use \"-b\" option !!!\n");
		skyeye_exit(-1);
	}

	ARMul_SelectProcessor(state, ARM_v4_Prop);
	state->lateabtSig = HIGH;

	state->Reg[1] = 377;

	this_mach->mach_io_do_cycle = MACH_IO_DO_CYCLE_FUNC(s3c3410x_io_do_cycle);
	this_mach->mach_io_reset = MACH_IO_RESET_FUNC(s3c3410x_io_reset);

	this_mach->mach_io_read_word = MACH_IO_READ_FUNC(s3c3410x_io_read_word);
	this_mach->mach_io_read_halfword = MACH_IO_READ_FUNC(s3c3410x_io_read_halfword);
	this_mach->mach_io_read_byte = MACH_IO_READ_FUNC(s3c3410x_io_read_byte);
	this_mach->mach_io_write_word = MACH_IO_WRITE_FUNC(s3c3410x_io_write_word);
	this_mach->mach_io_write_halfword = MACH_IO_WRITE_FUNC(s3c3410x_io_write_halfword);
	this_mach->mach_io_write_byte = MACH_IO_WRITE_FUNC(s3c3410x_io_write_byte);

	this_mach->mach_update_int = MACH_IO_UPDATE_INT_FUNC(s3c3410x_update_int);

	this_mach->state = (void*)state;
}

