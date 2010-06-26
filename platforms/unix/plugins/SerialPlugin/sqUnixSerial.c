/* sqUnixSerial.c -- Unix serial support
 * 
 * Author: Ned Konz, July 14, 2000
 * 
 * Last edited: 2002-10-26 14:36:11 by piumarta on emilia.inria.fr
 *
 * Separated from MIDI, plus various portability problems fixed, by:
 *	Ian Piumarta <Ian.Piumarta@INRIA.Fr>
 */

#include "sq.h"
#include "SerialPlugin.h"

#include <termios.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

/*** Module variables ***/

/* portNum	0=/dev/ttyS0, etc. */
/* include 1 byte for NUL at end */
#define PORT_NAME_SIZE 11
static const char serialPortBaseName[] = "/dev/ttyS0";

/* stopBits	0=1.5, 1=1, 2=2 */
/* I don't know how to get 1.5 stop bits. Oh well. So you get 2 instead */
#define MAX_STOP_BITS 2
/* c_cflag definitions */
static const unsigned int stopBitsDecode[MAX_STOP_BITS+1] = { CSTOPB, 0, CSTOPB };

/* dataBits	number of bits per character (5..8) */
/* note that since CS5 is 0, you will get 5 data bits if you ask for 0..4
 * as well */
#define MAX_DATA_BITS 8
/* c_cflag definitions */
static const unsigned int dataBitsDecode[MAX_DATA_BITS+1] = {
	0, 0, 0, 0, 0, CS5, CS6, CS7, CS8
};

/* parityType	0=no, 1=odd, 2=even  */
#define MAX_PARITY_TYPE 2
/* c_cflag definitions */
static const unsigned int parityTypeDecode[MAX_PARITY_TYPE+1] = {
	0,				/* none */
	PARENB|PARODD,	/* odd */
	PARENB			/* even */
};

/* inFlowCtrl	0=none, 1=XOn/XOff, 2=hardware handshaking
 * outFlowCtrl	0=none, 1=XOn/XOff, 2=hardware handshaking */
#define MAX_FLOW_CTRL 2

/* must be <= 10, because of 1-digit filename generation */
#define MAX_SERIAL_PORTS 10
static int serialFileDescriptors[MAX_SERIAL_PORTS];	/* index=squeak port# */
static struct termios savedSerialTermios[MAX_SERIAL_PORTS];	/* index=squeak port# */

/* dataRate	rate in bps */
typedef struct drDecode { int dataRate; speed_t code; } drDecode;
static drDecode dataRateDecode[] = {
	{ 0, B0 },		/* hang up */
	{ 50, B50 },
	{ 75, B75 },
	{ 110, B110 },
	{ 134, B134 },
	{ 150, B150 },
	{ 200, B200 },
	{ 300, B300 },
	{ 600, B600 },
	{ 1200, B1200 },
	{ 1800, B1800 },
	{ 2400, B2400 },
	{ 4800, B4800 },
	{ 9600, B9600 },
	{ 19200, B19200 },
	{ 38400, B38400 },
#       if defined(B57600)	/* missing on SunOS 4 */ 
	{ 57600, B57600 },
	{ 115200, B115200 },
#       endif
#       if defined(B230400)	/* missing on Digital Unix (ex DEC OSF/1) */
	{ 230400, B230400 },
#       endif
#       if defined(B460800)	/* missing on FreeBSD */
	{ 460800, B460800 },
#       endif
#       if defined(B500000)	/* missing on GNU/Linux prior to 2.2 */
	{ 500000, B500000 },
	{ 576000, B576000 },
	{ 921600, B921600 },
	{ 1000000, B1000000 },
	{ 1152000, B1152000 },
	{ 1500000, B1500000 },
	{ 2000000, B2000000 },
	{ 2500000, B2500000 },
	{ 3000000, B3000000 },
	{ 3500000, B3500000 },
	{ 4000000, B4000000 },
#       endif
	{ -1, B0 }			/* end marker */
};

/* This is the default setting for a termios structure on open */
static struct termios defaultTermios;

/*** Private Functions ***/

/* return the speed_t corresponding to the given data rate in bps,
 * or B0 if not found */
static speed_t serialDecodeSpeed(int speed)
{
	drDecode* p;
	for( p = dataRateDecode; p->dataRate >= 0; p++)
	{
		if (p->dataRate == speed)
			return p->code;
	}
	return B0;
}

/*** Public Functions ***/

/* return value ignored */
int serialPortClose(int portNum)
{
	int fd;
	if (portNum < 0 || portNum >= MAX_SERIAL_PORTS )
	{
		success(false);
		return 0;
	}
	/* Squeak wants to close already-closed ports... */
	if ((fd = serialFileDescriptors[ portNum ]) < 0)
	{
		success(true);
		return 0;
	}
	serialFileDescriptors[ portNum ] = -1;
	if (tcsetattr(fd, TCSAFLUSH, savedSerialTermios + portNum)
		|| close(fd))
	{
		success(false);
		return 0;
	}
	success(true);
	return 0;
}

/* Open the given serial port using the given settings. The data rate can be
 * any number that is in the table above; the driver is not as flexible
 * about the speed as the Mac driver, apparently. */
/* return value ignored */
int serialPortOpen(
		int portNum,
		int dataRate,
		int stopBitsType,
		int parityType,
		int dataBits,
		int inFlowCtrl,
		int outFlowCtrl,
		int xOnChar,
		int xOffChar)
{
	int fd;
	char serialPortName[ PORT_NAME_SIZE ];
	speed_t speed = serialDecodeSpeed( dataRate );
	struct termios flags;

	/* validate arguments */
	if (portNum < 0 || portNum >= MAX_SERIAL_PORTS
		|| speed == B0
		|| stopBitsType < 0 || stopBitsType > MAX_STOP_BITS
		|| parityType < 0 || parityType > MAX_PARITY_TYPE
		|| dataBits < 0 || dataBits > MAX_DATA_BITS
		|| inFlowCtrl < 0 || inFlowCtrl > MAX_FLOW_CTRL
		|| outFlowCtrl < 0 || outFlowCtrl > MAX_FLOW_CTRL
		|| (( inFlowCtrl == 1 || outFlowCtrl == 1 )
				&& ( xOnChar < 0 || xOnChar > 255
					|| xOffChar < 0 || xOffChar > 255 )))
	{
		success(false);
		return 0;
	}

	/* generate a filename (with last digit set to port number) */
	strcpy(serialPortName, serialPortBaseName);
	serialPortName[ PORT_NAME_SIZE - 2 ] = portNum + '0';

	/* open the device */
	if ((fd = open(serialPortName, O_RDWR|O_NONBLOCK|O_NOCTTY)) < 0)
	{
		success(false);
		return 0;
	}
	/* save the file descriptor */
	serialFileDescriptors[ portNum ] = fd;

	/* save the old state */
	if (tcgetattr(fd, savedSerialTermios + portNum))
	{
		success(false);
		return 0;
	}

	/* set up the new modes */
	flags = defaultTermios;

	/* input & output data rate */
	cfsetispeed(&flags, speed);
	cfsetospeed(&flags, speed);

	/* stop bits */
	flags.c_cflag &= ~CSTOPB;
	flags.c_cflag |= stopBitsDecode[ stopBitsType ];

	/* parity */
	flags.c_cflag &= ~(PARENB|PARODD);
	flags.c_cflag |= parityTypeDecode[ parityType ];

	/* data bits */
	flags.c_cflag &= ~CSIZE;
	flags.c_cflag |= dataBitsDecode[ dataBits ];

	/* flow control characters */
	if (inFlowCtrl == 1 || outFlowCtrl == 1)
	{
		flags.c_cc[ VSTART ] = xOnChar;
		flags.c_cc[ VSTOP ] = xOffChar;
	}

	flags.c_iflag &= ~(IXON|IXOFF|IXANY);

	if (inFlowCtrl == 1) flags.c_iflag |= IXOFF;
	if (outFlowCtrl == 1) flags.c_iflag |= IXON;

#	if defined(CRTSCTS)
	flags.c_cflag &= ~CRTSCTS;
 	if (inFlowCtrl == 2 || outFlowCtrl == 2) flags.c_cflag |= CRTSCTS;
#	else   /* not defined in IRIX!? */
	if (inFlowCtrl == 2 || outFlowCtrl == 2)
	{
		fprintf(stderr, "CRTSCTS not supported.\n");
		success(false);
		return 0;
	}
#	endif

	if (tcsetattr(fd, TCSANOW, &flags))	/* set it NOW */
	{
		success(false);
		return 0;
	}

	success(true);
	return 0;
}

/* Read up to count bytes from the given serial port into the given byte array.
   Read only up to the number of bytes in the port's input buffer; if fewer bytes
   than count have been received, do not wait for additional data to arrive.
   Return zero if no data is available, else number of bytes read */
int serialPortReadInto(int portNum, int count, int startPtr)
{
	int fd;
	ssize_t bytesRead;
	void* buffer = (void*)startPtr;		/* ints as pointers?? */

	if (portNum < 0
		|| portNum >= MAX_SERIAL_PORTS
		|| (fd = serialFileDescriptors[ portNum ]) < 0)
	{
		success(false);
		return 0;
	}

	bytesRead = read(fd, buffer, (size_t)count);
	if (bytesRead == (ssize_t)-1)
	{
		if (errno == EAGAIN)
			bytesRead = 0;
		else
		{
			success(false);
			return 0;
		}
	}

	success(true);
	return (int)bytesRead;
}

/* Write count bytes from the given byte array to the given serial port's
   output buffer. Return the number of bytes written. This implementation is
   synchronous: it doesn't return until the data has been sent. However, other
   implementations may return before transmission is complete. */
int serialPortWriteFrom(int portNum, int count, int startPtr)
{
	int fd;
	int bytesWritten;
	char* buffer = (void*)startPtr;

	if (portNum < 0
		|| portNum >= MAX_SERIAL_PORTS
		|| (fd = serialFileDescriptors[ portNum ]) < 0)
	{
		success(false);
		return 0;
	}

	bytesWritten = write(fd, buffer, (size_t)count);
	if (bytesWritten == (ssize_t)-1)
	{
		success(false);
		return 0;
	}

	success(true);
	return bytesWritten;
}

/* return true on success */
int serialPortInit(void)
{
	int i;

	/* initialize the file descriptors to invalid */
	for (i = 0; i < MAX_SERIAL_PORTS; i++)
		serialFileDescriptors[ i ] = -1;

	/* initialize our default termios structure (already 0'd) */
	defaultTermios.c_iflag = IGNBRK | IGNPAR;	/* ignore break, parity/framing errs */
	/* tcflag_t c_oflag output modes */
	/* defaultTermios.c_oflag = 0; */
	/* tcflag_t c_cflag control modes */
	defaultTermios.c_cflag = CREAD;
	/* tcflag_t c_lflag local modes */
	/* defaultTermios.c_lflag = 0; */
	/* cc_t c_cc[NCCS] control chars */
	defaultTermios.c_cc[VTIME] = 0;
	defaultTermios.c_cc[VMIN] = 0;

	success(true);
	return 1;
}

/* return true on success */
int serialPortShutdown(void)
{
	success(true);
	return 1;
}
