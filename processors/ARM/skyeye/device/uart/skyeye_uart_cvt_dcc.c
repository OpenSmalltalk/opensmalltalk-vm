/*
	skyeye_uart_cvt_dcc.c - skyeye JTAG Debug Communication Channel simulation
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
 * 2007.03.31	Written by Anthony Lee
 */

/*
 * NOTE:
 * 	THE CODES JUST BASED ON linux-2.6.x source
 * 		"linux-2.6.x/drivers/serial/dcc.c" by Hyok S. Choi (hyok.choi@samsung.com)
 */

#include "armdefs.h"
#include "skyeye_uart.h"

#define PRINT(x...)		printf("[JTAG_DCC]: " x)

struct uart_dcc_device {
	unsigned flags;

	struct uart_device *dev;

	int (*uart_close)(struct uart_device *uart_dev);
	int (*uart_read)(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout);
	int (*uart_write)(struct uart_device *uart_dev, void *buf, size_t count);
};

static struct uart_dcc_device dcc = {0, NULL, NULL, NULL, NULL};


static unsigned uart_dcc_cp14_mrc(ARMul_State *state, unsigned type, ARMword instr, ARMword *value)
{
	unsigned opcode_1 = BITS(21, 23);
	unsigned CRn = BITS(16, 19);
	unsigned CRm = BITS(0, 3);
	unsigned opcode_2 = BITS(5, 7);

	if (!(opcode_1 == 0 && opcode_2 == 0 && CRn < 2 && CRm == 0)) return ARMul_CANT;

	if ((dcc.flags & 0x1) && dcc.dev != NULL) {
		switch (CRn) {
			case 0: /* returns the Debug Comms Control Register into Rd */
				if ((dcc.flags & 0x2) == 0 && dcc.uart_read != NULL) {
					unsigned char c;
					struct timeval tv;

					tv.tv_sec = 0;
					tv.tv_usec = 0;
					if (dcc.uart_read(dcc.dev, &c, 1, &tv) > 0) {
						dcc.flags = 0x3 | (c << 2);
					}
				}

				*value = (dcc.flags & 0x2) == 0 ? 0 : 1; /* W bit always be 0 */

				break;

			case 1: /* returns the Debug data read register into Rd */
				*value = 0;
				if ((dcc.flags & 0x2) != 0) {
					*value = (dcc.flags >> 2) & 0xff;
					dcc.flags = 0x1;
				}
				break;

			default:
				break;
		}
	}

	return ARMul_DONE;
}


static unsigned uart_dcc_cp14_mcr(ARMul_State *state, unsigned type, ARMword instr, ARMword value)
{
	unsigned opcode_1 = BITS(21, 23);
	unsigned CRn = BITS(16, 19);
	unsigned CRm = BITS(0, 3);
	unsigned opcode_2 = BITS(5, 7);

	if (!(opcode_1 == 0 && opcode_2 == 0 && CRn == 1 && CRm == 0)) return ARMul_CANT;

	/* writes the value in Rn to the Comms Write Register */
	if ((dcc.flags & 0x1) && dcc.dev != NULL && dcc.uart_write != NULL) {
		unsigned char c = value & 0xff;

		dcc.uart_write(dcc.dev, &c, 1);
	}

	return ARMul_DONE;
}


static int uart_dcc_close(struct uart_device *uart_dev)
{
	if (dcc.flags != 0) {
		ARMul_CoProDetach((ARMul_State*)skyeye_config.mach->state, 14);
		dcc.dev->uart_close = dcc.uart_close;
		dcc.dev->uart_read = dcc.uart_read;
		dcc.dev->uart_write = dcc.uart_write;
		dcc.dev = NULL;
		dcc.flags = 0;

		if (uart_dev->uart_close != NULL) uart_dev->uart_close(uart_dev);
	}

	return 0;
}


static int uart_dcc_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout)
{
	return -1;
}


static int uart_dcc_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	return -1;
}


void skyeye_uart_converter_dcc_setup(struct uart_device *uart_dev)
{
	ARMul_State *state;

	if (skyeye_config.arch == NULL ||
	    skyeye_config.arch->arch_name == NULL ||
	    strcmp(skyeye_config.arch->arch_name, "arm") != 0 ||
	    skyeye_config.mach == NULL ||
	    (state = (ARMul_State*)skyeye_config.mach->state) == NULL ||
	    state->is_XScale != 0) {
		PRINT("*** ERROR: Unsupported architecture !!!\n");
		return;
	}

	if (dcc.flags != 0) {
		PRINT("*** ERROR: JTAG DCC has been installed !!!\n");
		return;
	}

	dcc.flags = 0x1;
	dcc.dev = uart_dev;
	dcc.uart_close = uart_dev->uart_close;
	dcc.uart_read = uart_dev->uart_read;
	dcc.uart_write= uart_dev->uart_write;

	uart_dev->uart_close = uart_dcc_close;
	uart_dev->uart_read = uart_dcc_read;
	uart_dev->uart_write = uart_dcc_write;

	ARMul_CoProAttach(state, 14,
			  NULL, NULL,
			  NULL, NULL,
			  uart_dcc_cp14_mrc, uart_dcc_cp14_mcr,
			  NULL,
			  NULL, NULL);
}

