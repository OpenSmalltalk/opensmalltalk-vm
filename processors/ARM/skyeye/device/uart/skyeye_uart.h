/*
	skyeye_uart.h - skyeye uart device support functions
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

#ifndef __SKYEYE_UART_H_
#define __SKYEYE_UART_H_

#include <sys/time.h>

#include "skyeye_device.h"
#include "skyeye_config.h"

/* uart simulation type */
#define UART_SIM_STDIO		0	/* use stdin and stdout as fd */
#define UART_SIM_PIPE		1	/* use file (pipe file) or device(/dev/ttyS1) as fd */
#define UART_SIM_NET		2	/* use tcp port as fd */

struct uart_device {
	int mod;

	char desc_in[MAX_STR_NAME];	/* description of device, such as path etc. */
	char desc_out[MAX_STR_NAME];	/* description of device, such as path etc. */

	/* private data. */
	void *priv;

	int (*uart_open)(struct uart_device *uart_dev);
	int (*uart_close)(struct uart_device *uart_dev);
	int (*uart_read)(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout);
	int (*uart_write)(struct uart_device *uart_dev, void *buf, size_t count);

	char converter[MAX_STR_NAME];
	void *converter_priv; /* converter private data. */
};

void skyeye_uart_cleanup();
int skyeye_uart_setup(struct uart_option *uart_opt);


/* converter */
void skyeye_uart_converter_setup(void);
void skyeye_uart_converter_dcc_setup(struct uart_device *uart_dev);


/* modules */
int uart_stdio_open(struct uart_device *uart_dev);
int uart_stdio_close(struct uart_device *uart_dev);
int uart_stdio_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout);
int uart_stdio_write(struct uart_device *uart_dev, void *buf, size_t count);

int uart_pipe_open(struct uart_device *uart_dev);
int uart_pipe_close(struct uart_device *uart_dev);
int uart_pipe_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout);
int uart_pipe_write(struct uart_device *uart_dev, void *buf, size_t count);

int uart_net_open(struct uart_device *uart_dev);
int uart_net_close(struct uart_device *uart_dev);
int uart_net_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout);
int uart_net_write(struct uart_device *uart_dev, void *buf, size_t count);


/* helper functions */

/* skyeye_uart_read(), skyeye_uart_write():
 * devIndex:
 * 	>= 0	---	the index of device
 * 	< 0	---	all devices, skyeye_uart_write() return the maximum bytes of the actions
 * retDevIndex:
 * 	if you don't pass NULL to it, skyeye_uart_read() replace the value of it be the index of device that got something.
 * wroteBytes:
 * 	if you don't pass NULL to it, skyeye_uart_write() replace the value of it be the bytes of each action of devices.
 */
int skyeye_uart_read(int devIndex, void *buf, size_t count, struct timeval *timeout, int *retDevIndex);
int skyeye_uart_write(int devIndex, void *buf, size_t count, int *wroteBytes[MAX_UART_DEVICE_NUM]);

#endif	/* __SKYEYE_UART_H_ */

