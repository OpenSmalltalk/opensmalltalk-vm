/*
	skyeye_uart.c - skyeye uart device support functions
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
 * 2007.01.18	by Anthony Lee : initial version
 */

#include "skyeye_config.h"
#include "skyeye_uart.h"
#include "portable/gettimeofday.h"
#include "portable/usleep.h"

struct uart_converter
{
	char name[MAX_STR_NAME];
	void (*setup)(struct uart_device *uart_dev);
};


static struct uart_converter uart_cvts[] = {
	/* name		setup */
	{ "dcc",	skyeye_uart_converter_dcc_setup },
	{ "",		NULL },
};

static int skyeye_uart_stdio_once_flag = 0;


static int skyeye_uart_check_timeout(struct timeval *tv)
{
	struct timeval cur_time;

	if (tv == NULL) return 1;
	if (gettimeofday(&cur_time, NULL) != 0) return -1;

	if (cur_time.tv_sec > tv->tv_sec) return 0;
	if (cur_time.tv_sec == tv->tv_sec && cur_time.tv_usec >= tv->tv_usec) return 0;

	return 1;
}


int skyeye_uart_read(int devIndex, void *buf, size_t count, struct timeval *timeout, int *retDevIndex)
{
	int retVal = -1;
	struct uart_device *uart_dev;

	if (retDevIndex != NULL) *retDevIndex = -1;

	if (devIndex >= skyeye_config.uart.count || buf == NULL || count == 0) { /* invalid */
	} else if(devIndex >= 0) { /* single device */
		uart_dev = skyeye_config.uart.devs[devIndex];
		retVal = uart_dev->uart_read(uart_dev, buf, count, timeout);
	} else { /* all devices */
		int i, stop_flags = 0;
		struct timeval tv, zero_tv;

		if (!(timeout == NULL || gettimeofday(&tv, NULL) == 0)) { /* something error */
		} else {
			if (timeout != NULL) {
				tv.tv_sec += (timeout->tv_sec + (timeout->tv_usec + tv.tv_usec) / 1000000UL);
				tv.tv_usec = (timeout->tv_usec + tv.tv_usec) % 1000000UL;
			}

			zero_tv.tv_sec = 0;
			zero_tv.tv_usec = 0;

			do {
				for (i = 0; i < skyeye_config.uart.count; i++) {
					uart_dev = skyeye_config.uart.devs[i];
					retVal = uart_dev->uart_read(uart_dev, buf, count, &zero_tv);

					if(retVal > 0) { /* got something */
						devIndex = i;
						break;
					}
					if(retVal == 0) continue;
					stop_flags |= (1 << i); /* failed */
				}

				if (stop_flags == (1 << skyeye_config.uart.count) - 1) { /* all failed */
					retVal = -1;
				} else if (retVal > 0) {
					stop_flags = 1;
				} else {
					retVal = 0;

					if (skyeye_uart_check_timeout(timeout != NULL ? &tv : NULL) == 1) { /* polling */
						stop_flags = 0;
						usleep(500);
					} else { /* timeout */
						stop_flags = 1;
					}
				}
			} while (stop_flags == 0);
		}
	}

	if (retVal > 0 && retDevIndex != NULL) *retDevIndex = devIndex;

	return retVal;
}


int skyeye_uart_write(int devIndex, void *buf, size_t count, int *wroteBytes[MAX_UART_DEVICE_NUM])
{
	int i = (devIndex < 0 ? skyeye_config.uart.count - 1 : devIndex);
	int retVal = -1;
	int nWrote = 0;

	if (i < 0 || i >= skyeye_config.uart.count) return -1;

	do {
		nWrote = skyeye_config.uart.devs[i]->uart_write(skyeye_config.uart.devs[i], buf, count);
		if (wroteBytes != NULL) (*wroteBytes)[i] = nWrote;
		retVal = max(retVal, nWrote);
	} while (--i >= 0 && devIndex < 0);

	return retVal;
}


/* skyeye_uart_cleanup(): for cleanup stack on exit */
void skyeye_uart_cleanup()
{
	int i = skyeye_config.uart.count;
	struct uart_device *dev;

	skyeye_config.uart.count = 0;
	while (--i >= 0) {
		dev = skyeye_config.uart.devs[i];
		dev->uart_close(dev);
		free(dev);
	}
}


/* skyeye_uart_setup(): setup device when analyzing uart options */
int skyeye_uart_setup(struct uart_option *uart_opt)
{
	struct uart_device *uart_dev;
	int ret = -1;

	if (skyeye_config.uart.count >= MAX_UART_DEVICE_NUM) return -1;

	uart_dev = (struct uart_device *)malloc(sizeof(struct uart_device));
	if (uart_dev == NULL) return -1;

	memset(uart_dev, 0, sizeof(struct uart_device));

	uart_dev->mod = uart_opt->mod;
	memcpy(&uart_dev->desc_in[0], &uart_opt->desc_in[0], MAX_STR_NAME);
	memcpy(&uart_dev->desc_out[0], &uart_opt->desc_out[0], MAX_STR_NAME);
	memcpy(&uart_dev->converter[0], &uart_opt->converter[0], MAX_STR_NAME);

	printf("uart_mod:%d, desc_in:%s, desc_out:%s, converter:%s\n",
	       uart_dev->mod, uart_dev->desc_in, uart_dev->desc_out, uart_dev->converter);

	switch (uart_dev->mod) {
		case UART_SIM_STDIO:
			if (skyeye_uart_stdio_once_flag != 0) break;
			uart_dev->uart_open = uart_stdio_open;
			uart_dev->uart_close = uart_stdio_close;
			uart_dev->uart_read = uart_stdio_read;
			uart_dev->uart_write = uart_stdio_write;
			ret = 0;
			break;

		case UART_SIM_PIPE:
			uart_dev->uart_open = uart_pipe_open;
			uart_dev->uart_close = uart_pipe_close;
			uart_dev->uart_read = uart_pipe_read;
			uart_dev->uart_write = uart_pipe_write;
			ret = 0;
			break;

		case UART_SIM_NET:
			uart_dev->uart_open = uart_net_open;
			uart_dev->uart_close = uart_net_close;
			uart_dev->uart_read = uart_net_read;
			uart_dev->uart_write = uart_net_write;
			ret = 0;
			break;

		default:
			break;
	}

	if (ret == 0) {
		if(uart_dev->uart_open(uart_dev) == 0) {
			skyeye_config.uart.devs[skyeye_config.uart.count++] = uart_dev;
			if(uart_dev->mod == UART_SIM_STDIO) skyeye_uart_stdio_once_flag = 1;
		} else {
			ret = -1;
		}
	}

	if (ret != 0) {
		free(uart_dev);
		uart_dev = NULL;
	}

	return ret;
}


/* skyeye_uart_converter_setup(): setup converter of uart devices after machine initalized */
void skyeye_uart_converter_setup(void)
{
	struct uart_device *uart_dev;
	int i, k;

	for (i = 0; i < skyeye_config.uart.count; i++) {
		uart_dev = skyeye_config.uart.devs[i];
		if (uart_dev->converter[0] == 0) continue;

		for (k = 0; uart_cvts[k].setup != NULL; k++) {
			if (strncmp(&uart_dev->converter[0], &uart_cvts[k].name[0], MAX_STR_NAME) == 0) {
					(*(uart_cvts[k].setup))(uart_dev);
			}
		}
	}
}

