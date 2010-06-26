/*
	skyeye_uart_pipe.c - skyeye uart device from pipe or device
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

#ifdef __BEOS__
#include <BeBuild.h>
#endif

#if (defined(__MINGW32__) || (defined(__BEOS__) && B_BEOS_VERSION < 0x510))
#define SKYEYE_UART_PIPE_POSIX_SUPPORTED 0
#else
#define SKYEYE_UART_PIPE_POSIX_SUPPORTED 1
#endif

#if SKYEYE_UART_PIPE_POSIX_SUPPORTED

#include <sys/select.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>

typedef struct uart_pipe_t {
	int fd_in;
	int fd_out;
} uart_pipe_t;


int uart_pipe_open(struct uart_device *uart_dev)
{
	uart_pipe_t *dev = malloc(sizeof(uart_pipe_t));
	int ret = 0;

	if(dev == NULL) return -1;

	if(uart_dev->desc_in[0] == '\0')
	{
		ret = -1;
	}
	else if(uart_dev->desc_out[0] == '\0' || strcmp(uart_dev->desc_in, uart_dev->desc_out) == 0)
	{
		dev->fd_out = -1;
		if((dev->fd_in = open(uart_dev->desc_in, O_RDWR)) == -1)
		{
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" !!!", uart_dev->desc_in);
		}
	}
	else
	{
		if((dev->fd_in = open(uart_dev->desc_in, O_RDONLY)) == -1)
		{
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" for input !!!", uart_dev->desc_in);
		}
		else if((dev->fd_out = open(uart_dev->desc_out, O_WRONLY)) == -1)
		{
			close(dev->fd_in);
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" for output !!!", uart_dev->desc_out);
		}
	}

	if(ret == 0) uart_dev->priv = (void*)dev;
	else free(dev);

	return ret;
}


int uart_pipe_close(struct uart_device *uart_dev)
{
	uart_pipe_t *dev = (uart_pipe_t*)uart_dev->priv;

	if(dev == NULL) return -1;

	if(dev->fd_in != -1) close(dev->fd_in);
	if(dev->fd_out != -1) close(dev->fd_out);
	free(dev);

	uart_dev->priv = NULL;

	return 0;
}


int uart_pipe_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout)
{
	fd_set rfds;
	uart_pipe_t *dev = (uart_pipe_t*)uart_dev->priv;

	if(dev == NULL) return -1;

	FD_ZERO(&rfds);
	FD_SET(dev->fd_in, &rfds);

	if(select(dev->fd_in + 1, &rfds, NULL, NULL, timeout) != 1 || !FD_ISSET(dev->fd_in, &rfds)) return 0;

	return read(dev->fd_in, buf, count);
}


int uart_pipe_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	uart_pipe_t *dev = (uart_pipe_t*)uart_dev->priv;

	if(dev == NULL) return -1;

	return write((dev->fd_out != -1 ? dev->fd_out : dev->fd_in), buf, count);
}

#else /* !SKYEYE_UART_PIPE_POSIX_SUPPORTED */

#if (defined(__MINGW32__) || defined(__CYGWIN__))

#undef WORD
#undef byte
#include <windows.h>

#define PIPE_BUFFER_SIZE	1

typedef struct uart_pipe_win32 {
	HANDLE fHandle;
	HANDLE fHandleOut;
	HANDLE fEvent;
	HANDLE fEventOut;

	unsigned char fBuffer[PIPE_BUFFER_SIZE];
	DWORD fBufferLen;

	CRITICAL_SECTION fLocker;
	BOOL fReading;
	OVERLAPPED fOverlapped;
	OVERLAPPED fOverlappedOut;

	DWORD fWritten;
} uart_pipe_win32;


int uart_pipe_open(struct uart_device *uart_dev)
{
	uart_pipe_win32 *dev = malloc(sizeof(uart_pipe_win32));
	int ret = 0;

	if(dev == NULL) return -1;
	bzero(dev, sizeof(uart_pipe_win32));

	if(strncmp(&uart_dev->desc_in[0], "/dev/ttyS", 9) == 0 &&
	   uart_dev->desc_in[9] >= '0' && uart_dev->desc_in[9] <= '8' &&
	   uart_dev->desc_in[10] == 0) {
		memcpy(&uart_dev->desc_in[0], "COM\0", 5);
		uart_dev->desc_in[3] = uart_dev->desc_in[9] + 1;
	}

	if(strncmp(&uart_dev->desc_out[0], "/dev/ttyS", 9) == 0 &&
	   uart_dev->desc_out[9] >= '0' && uart_dev->desc_out[9] <= '8' &&
	   uart_dev->desc_out[10] == 0) {
		memcpy(&uart_dev->desc_out[0], "COM\0", 5);
		uart_dev->desc_out[3] = uart_dev->desc_out[9] + 1;
	}

	if(uart_dev->desc_in[0] == '\0')
	{
		ret = -1;
	}
	else if(uart_dev->desc_out[0] == '\0' || strcmp(uart_dev->desc_in, uart_dev->desc_out) == 0)
	{
		if((dev->fHandle = CreateFile(uart_dev->desc_in,
					      GENERIC_READ | GENERIC_WRITE,
					      FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
					      OPEN_EXISTING,
					      FILE_FLAG_OVERLAPPED,
					      NULL)) == INVALID_HANDLE_VALUE)
		{
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" !!!\n", uart_dev->desc_in);
		}
	}
	else
	{
		if((dev->fHandle = CreateFile(uart_dev->desc_in,
					      GENERIC_READ,
					      FILE_SHARE_READ, NULL,
					      OPEN_EXISTING,
					      FILE_FLAG_OVERLAPPED,
					      NULL)) == INVALID_HANDLE_VALUE)
		{
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" for input !!!\n", uart_dev->desc_in);
		}
		else if((dev->fHandleOut = CreateFile(uart_dev->desc_out,
						      GENERIC_WRITE,
						      FILE_SHARE_WRITE, NULL,
						      OPEN_EXISTING,
						      FILE_FLAG_OVERLAPPED,
						      NULL)) == INVALID_HANDLE_VALUE)
		{
			CloseHandle(dev->fHandle);
			ret = -1;
			fprintf(stderr, "Error when open device \"%s\" for output !!!\n", uart_dev->desc_out);
		}
	}

	if(ret != 0)
	{
		free(dev);
		return ret;
	}

	InitializeCriticalSection(&dev->fLocker);
	dev->fEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
	dev->fEventOut = CreateEvent(NULL, FALSE, FALSE, NULL);

	uart_dev->priv = (void*)dev;

	return 0;
}


int uart_pipe_close(struct uart_device *uart_dev)
{
	uart_pipe_win32 *dev = (uart_dev ? (uart_pipe_win32*)(uart_dev->priv) : NULL);
	if(dev == NULL) return -1;

	CloseHandle(dev->fHandle);
	if(dev->fHandleOut) CloseHandle(dev->fHandleOut);
	CloseHandle(dev->fEvent);
	CloseHandle(dev->fEventOut);
	DeleteCriticalSection(&dev->fLocker);

	uart_dev->priv = NULL;

	return 0;
}


static void CALLBACK uart_pipe_read_callback(DWORD dwErrorCode, DWORD dwNumberOfBytesTransfered, LPOVERLAPPED lpOverlapped)
{
	uart_pipe_win32 *dev = (uart_pipe_win32*)lpOverlapped->hEvent;
	if(dev == NULL) return;

	EnterCriticalSection(&dev->fLocker);

	dev->fReading = FALSE;
	dev->fBufferLen = (dwErrorCode == 0 ? dwNumberOfBytesTransfered : 0);
	SetEvent(dev->fEvent);

	LeaveCriticalSection(&dev->fLocker);
}


static void CALLBACK uart_pipe_write_callback(DWORD dwErrorCode, DWORD dwNumberOfBytesTransfered, LPOVERLAPPED lpOverlapped)
{
	uart_pipe_win32 *dev = (uart_pipe_win32*)lpOverlapped->hEvent;
	if(dev == NULL) return;

	dev->fWritten = (dwErrorCode == 0 ? dwNumberOfBytesTransfered : 0);
	SetEvent(dev->fEventOut);
}


int uart_pipe_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *tv)
{
	uart_pipe_win32 *dev = (uart_dev ? (uart_pipe_win32*)(uart_dev->priv) : NULL);
	int retVal = 0, flags = 1;
	DWORD status;

	if(dev == NULL) return -1;

restart:
	EnterCriticalSection(&dev->fLocker);

	if(dev->fReading)
	{
		retVal = 0;
	}
	else if(dev->fBufferLen == 0)
	{
		retVal = 0;

		dev->fReading = TRUE;
		dev->fOverlapped.Internal = 0;
		dev->fOverlapped.InternalHigh = 0;
		dev->fOverlapped.Offset = 0;
		dev->fOverlapped.OffsetHigh = 0;
		dev->fOverlapped.hEvent = dev;
		ResetEvent(dev->fEvent);

		if(ReadFileEx(dev->fHandle, &dev->fBuffer[0], PIPE_BUFFER_SIZE,
			      &dev->fOverlapped, uart_pipe_read_callback) == 0)
		{
			dev->fReading = FALSE;
			retVal = -1;
		}
	}
	else
	{
		retVal = min((int)dev->fBufferLen, count);
		memcpy(buf, &dev->fBuffer[0], (size_t)retVal);

		if(count < dev->fBufferLen)
			memmove(&dev->fBuffer[0], &dev->fBuffer[count], dev->fBufferLen - count);

		dev->fBufferLen -= retVal;
	}

	LeaveCriticalSection(&dev->fLocker);

	if(retVal == 0 && flags == 1)
	{
		DWORD timeout = (tv == NULL ? INFINITE : (DWORD)(tv->tv_sec * 1000UL + tv->tv_usec / 1000UL));
		while(TRUE)
		{
			status = WaitForSingleObjectEx(dev->fEvent, timeout, TRUE);
			if(status == WAIT_IO_COMPLETION && tv == NULL) continue;
			if(status == WAIT_OBJECT_0)
			{
				flags = 0;
				goto restart;
			}
			break;
		}
	}

	return retVal;
}


int uart_pipe_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	uart_pipe_win32 *dev = (uart_dev ? (uart_pipe_win32*)(uart_dev->priv) : NULL);
	DWORD written = 0, status;
	HANDLE handle;

	if(dev == NULL) return -1;

	handle = (dev->fHandleOut == NULL ? dev->fHandle : dev->fHandleOut);

	dev->fOverlappedOut.Internal = 0;
	dev->fOverlappedOut.InternalHigh = 0;
	dev->fOverlappedOut.Offset = 0;
	dev->fOverlappedOut.OffsetHigh = 0;
	dev->fOverlappedOut.hEvent = dev;
	dev->fWritten = 0;

	if(WriteFileEx(handle, buf, (DWORD)count, &dev->fOverlappedOut, uart_pipe_write_callback) != 0)
	{
		while(TRUE)
		{
			status = WaitForSingleObjectEx(dev->fEventOut, INFINITE, TRUE);
			if(status == WAIT_IO_COMPLETION) continue;
			if(status == WAIT_OBJECT_0) written = dev->fWritten;
			break;
		}
	}

	return (int)written;
}

#else /* other system */

int uart_pipe_open(struct uart_device *uart_dev)
{
	return -1;
}


int uart_pipe_close(struct uart_device *uart_dev)
{
	return -1;
}


int uart_pipe_read(struct uart_device *uart_dev, void *buf, size_t count, struct timeval *timeout)
{
	return -1;
}


int uart_pipe_write(struct uart_device *uart_dev, void *buf, size_t count)
{
	return -1;
}

#endif

#endif /* SKYEYE_UART_PIPE_POSIX_SUPPORTED */


