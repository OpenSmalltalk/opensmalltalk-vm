/*
	skyeye_uart_stdio.c - skyeye uart device from standard input/output
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

#include "skyeye_uart.h"

#ifndef __MINGW32__

#ifdef __BEOS__
	#include <BeBuild.h>
	#if (B_BEOS_VERSION >= 0x510)
		#include <sys/select.h>
	#else /* B_BEOS_VERSION < 0x510 */
		#define SELECT_UNSUPPORTED
	#endif /* B_BEOS_VERSION >= 0x510 */
#else /* !__BEOS__ */
	#include <sys/select.h>
#endif /* __BEOS__ */

#ifdef SELECT_UNSUPPORTED
	#include <stdint.h>
	#include "portable/usleep.h"
#endif /* SELECT_UNSUPPORTED */

#include <unistd.h>

#include <termios.h>

int uart_stdio_open(struct uart_device *uart_dev)
{
	struct termios tmp;

	if((uart_dev->priv = malloc(sizeof(struct termios))) == NULL) return -1;

	tcgetattr(0, &tmp);
	memcpy(uart_dev->priv, &tmp, sizeof(struct termios));

	/* Set the terminal for non-blocking per-character (not per-line) input, no echo */
	tmp.c_lflag &= ~ICANON;
	tmp.c_lflag |= ISIG;
	tmp.c_lflag &= ~ECHO;
	tmp.c_cc[VMIN] = 0;
	tmp.c_cc[VTIME] = 0;
	tcsetattr(0, TCSANOW, &tmp);

	return 0;
}


int uart_stdio_close(struct uart_device *uart_dev)
{
	if(uart_dev->priv != NULL)
	{
		/* Restore the original terminal settings */
		tcsetattr(0, TCSANOW, (struct termios*)uart_dev->priv);
		free(uart_dev->priv);
		uart_dev->priv = NULL;
	}

	return 0;
}


int uart_stdio_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout)
{
	/*
	 * 2007-03-03 by Anthony Lee : for the system that don't support select().
	 * WHY: maybe useful for real-time improvement.
	 */
#ifndef SELECT_UNSUPPORTED

	fd_set rfds;

	FD_ZERO(&rfds);
	FD_SET(0, &rfds);

	if(select(1, &rfds, NULL, NULL, timeout) != 1 || !FD_ISSET(0, &rfds)) return 0;
	return read(0, buf, count);

#else /* SELECT_UNSUPPORTED */

	int retVal;
	int64_t time_left;

	if(timeout != NULL) time_left = (int64_t)timeout->tv_sec * (int64_t)1000000 + (int64_t)timeout->tv_usec;
	while(1)
	{
		/* for non-blocking input, instead of polling. */
		if((retVal = read(0, buf, count)) != 0) break;
		if(timeout == NULL) continue;
		if(time_left <= 0) break;
		usleep(1000);
		time_left -= (int64_t)1000;
	}

	return retVal;

#endif /* !SELECT_UNSUPPORTED */
}


int uart_stdio_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	return write(1, buf, count);
}

#else /* __MINGW32__ */

#undef WORD
#undef byte
#include <windows.h>

int uart_stdio_open(struct uart_device *uart_dev)
{
	char *term = getenv("TERM");
	DWORD console_mode = 0;

	if(term ? (strcmp(term, "xterm") == 0 || strcmp(term, "msys") == 0) : 0) /* rxvt shell */
	{
		/* TODO */
		fprintf(stderr, "\x1b[31m***\n"
				"*** [UART_STDIO_WIN32]: unsupported for rxvt shell !!!\n"
				"***\tyou should add \"GOTO: startsh\" to the target of\n"
				"***\tthe link pointed to \"msys.bat\".\n"
				"***\n\x1b[0m");
		skyeye_exit(-1);
	}

	if(GetStdHandle(STD_INPUT_HANDLE) == NULL || GetStdHandle(STD_INPUT_HANDLE) == INVALID_HANDLE_VALUE)
	{
		AllocConsole();
		Sleep(500);
	}
	GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), &console_mode);

	/* Set the terminal for non-blocking per-character (not per-line) input, no echo */
	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), console_mode & ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT));

	uart_dev->priv = (void*)console_mode;

	return 0;
}


int uart_stdio_close(struct uart_device *uart_dev)
{
	/* Restore the original terminal settings */
	SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), (DWORD)uart_dev->priv);

	return 0;
}


int uart_stdio_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout)
{
	int flags = -1;
	DWORD status;

	HANDLE handle = NULL;
	DWORD nRead = 0;
	INPUT_RECORD input;
	DWORD nEvents = 0;

	/* 2007-01-24 modified by Anthony Lee : for working on Windows 9x */
	DWORD msec = (timeout == NULL ? INFINITE : (DWORD)(timeout->tv_sec * 1000UL + timeout->tv_usec / 1000UL));

	handle = GetStdHandle(STD_INPUT_HANDLE);
	if(handle == NULL || handle == INVALID_HANDLE_VALUE)
	{
		fprintf(stderr, "%s: Unable to get handle.\n", __FUNCTION__);
		return -1;
	}

	status = WaitForSingleObject(handle, msec);
	if(status == WAIT_TIMEOUT) flags = 0; /* timeout */
	else if(status == WAIT_OBJECT_0) flags = 1; /* got something */

	if(flags <= 0) return flags;

	/* non-blocking stardand input */
	/* FIXME: IT IS NOT GOOD */
	while(!(GetNumberOfConsoleInputEvents(handle, &nEvents) == 0 || nEvents == 0) && nRead < count)
	{
		DWORD code;

		if(ReadConsoleInput(handle, &input, 1, &nEvents) == 0 || nEvents != 1) break;
		if(input.EventType != KEY_EVENT) continue;
		if(input.Event.KeyEvent.bKeyDown == FALSE) continue;
		code = input.Event.KeyEvent.wVirtualKeyCode;
		if(code == VK_SHIFT || code == VK_MENU || code == VK_CONTROL || code == VK_LWIN || code == VK_RWIN ||
		   code == VK_APPS || code == VK_CAPITAL || code == VK_SCROLL || code == VK_NUMLOCK) continue;
		*(((char*)buf) + (nRead++)) = input.Event.KeyEvent.uChar.AsciiChar;
	}

	return (int)nRead;
}


int uart_stdio_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	HANDLE handle = NULL;
	DWORD nWritten = 0;

	handle = GetStdHandle(STD_OUTPUT_HANDLE);
	if(handle == NULL || handle == INVALID_HANDLE_VALUE)
	{
		fprintf(stderr, "%s: Unable to get handle.\n", __FUNCTION__);
		return -1;
	}

	if(!WriteFile(handle, buf, count, &nWritten, NULL)) return -1;

	return (int)nWritten;
}

#endif /* !__MINGW32__ */


