/* sqUnixSerial.c -- Unix serial support
 * 
 * Last edited: 2011-03-14 14:01:56 by piumarta on emilia.ipe.media.kyoto-u.ac.jp
 */

#include "sq.h"
#include "SerialPlugin.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>

/*** Module variables ***/

#define PORT_NAME_SIZE 64

static const char serialPortBaseName[]		= "/dev/tty";
static const char serialPortBaseNameDefault[]	= "/dev/ttyS0";

/* stopBits	0=1.5, 1=1, 2=2 */
/* I don't know how to get 1.5 stop bits. Oh well. So you get 2 instead */
#define MAX_STOP_BITS 2
/* c_cflag definitions */
static const unsigned int stopBitsDecode[MAX_STOP_BITS + 1] = { CSTOPB, 0, CSTOPB };

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
  0,			/* none */
  PARENB | PARODD,	/* odd */
  PARENB		/* even */
};

/* inFlowCtrl	0=none, 1=XOn/XOff, 2=hardware handshaking
 * outFlowCtrl	0=none, 1=XOn/XOff, 2=hardware handshaking */
#define MAX_FLOW_CTRL 2

typedef struct _serial_port_type
{
  char spName[PORT_NAME_SIZE];
  int spDescriptor;
  struct termios spTermios;
} serial_port_type;

/* must be <= 10, because of 1-digit filename generation */
#define MAX_SERIAL_PORTS 32
static int sp_count= 0;
static serial_port_type previousSerialFiles[MAX_SERIAL_PORTS];	/* index=squeak port# */

/* dataRate	rate in bps */
typedef struct drDecode { int dataRate; speed_t code; } drDecode;
static drDecode dataRateDecode[] = {
  { 0, B0 },			/* hang up */
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
#if defined(B57600)		/* missing on SunOS 4 */ 
  { 57600, B57600 },
  { 115200, B115200 },
#endif
#if defined(B230400)		/* missing on Digital Unix (ex DEC OSF/1) */
  { 230400, B230400 },
#endif
#if defined(B460800)		/* missing on FreeBSD */
  { 460800, B460800 },
#endif
#if defined(B500000)		/* missing on GNU/Linux prior to 2.2 */
  { 500000, B500000 },
  { 576000, B576000 },
  { 921600, B921600 },
  { 1000000, B1000000 },
  { 1152000, B1152000 },
  { 1500000, B1500000 },
  { 2000000, B2000000 },
#endif
#if defined(B2500000)		/* missing on GNU/Linux Sparc64 */
  { 2500000, B2500000 },
  { 3000000, B3000000 },
  { 3500000, B3500000 },
  { 4000000, B4000000 },
#endif
  { -1, B0 }			/* end marker */
};

/* This is the default setting for a termios structure on open */
static struct termios defaultTermios;

/*** Private Functions ***/

/* return the speed_t corresponding to the given data rate in bps,
 * or B0 if not found */
static speed_t serialDecodeSpeed(int speed)
{
  drDecode *p;
  for (p= dataRateDecode;  p->dataRate >= 0;  p++)
    {
      if (p->dataRate == speed)
	return p->code;
    }
  return B0;
}

/* Compare entries in previousSerialFiles. */

int serial_port_cmp(const serial_port_type *sp1, const serial_port_type *sp2)
{
  return strcmp(sp1->spName, sp2->spName);
}

/* Return a previously-opened serial port by name, or NULL if the serial port was not found. */

serial_port_type *find_stored_serialport (const char *serialPortName)
{
  serial_port_type target, *result;
  strcpy((&target)->spName, serialPortName);
  result= bsearch(&target, &previousSerialFiles, sp_count, sizeof (serial_port_type), (int(*)(const void *, const void *))serial_port_cmp);
  return result;
}

/* generate a serial port filename (with last digit set to port number).
 * If the port number is greater than 9, the portnumber is defaulted to 0. */

void make_portname_from_portnum(char *serialPortName, const int portNum)
{
  strcpy(serialPortName, serialPortBaseNameDefault);
  if (portNum <= 9) serialPortName[strlen(serialPortName) - 1]= '0' + portNum;
}

/*** Public Functions ***/

/* return value ignored */
int serialPortClose(int portNum)
{
  char serialPortName[PORT_NAME_SIZE];

  if (portNum < 0 || portNum >= MAX_SERIAL_PORTS)
    {
      success(false);
      return 0;
    }
	
  make_portname_from_portnum(serialPortName, portNum);
        
  return serialPortCloseByName(serialPortName);
}

int serialPortCloseByName(const char *portName)
{
  serial_port_type * sp= find_stored_serialport(portName);
	
  /* Squeak wants to close inexistant or already-closed ports... */
  if (sp == NULL || sp->spDescriptor < 0)
    {
      success(true);
      return 0;
    }
	
  if (tcsetattr(sp->spDescriptor, TCSAFLUSH, &sp->spTermios))
    {
      fprintf(stderr, "Error while unsetting the com port parameter (errno:%d)\n", errno);
      success(false);
      return -1;
    }

  if (close(sp->spDescriptor))
    {
      fprintf(stderr, "Error while closing the com port (errno:%d)\n", errno);
      success(false);
      return -1;
    }

  /* Invalidate descriptor but leave name entry. If file will be reopened
   * the same entry will be used. */
  sp->spDescriptor= -1;

  success(true);
  return 0;
}

/* Open the given serial port using the given port number.
 * "/dev/ttySxx" port name are assumed. */
int serialPortOpen(int portNum, int dataRate, int stopBitsType, int parityType, int dataBits,
		   int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar)
{	
  char serialPortName[PORT_NAME_SIZE];
  make_portname_from_portnum(serialPortName, portNum);
      
  return serialPortOpenByName(serialPortName, dataRate, stopBitsType, parityType, dataBits,
			      inFlowCtrl, outFlowCtrl, xOnChar, xOffChar);
}

/* If anything goes wrong during opening make sure the file descriptor
 * is closed again, if it was opened already. */
static int portOpenFailed(serial_port_type *sp)
{
  if (sp && 0 <= sp->spDescriptor)
    {
      if (close(sp->spDescriptor))
	{
	  fprintf(stderr, "Error while closing the com port (errno:%d)\n", errno);
	}
      sp->spDescriptor= -1;
    }

  success(false);
  return -1;
}

/* Open the given serial port using the given node as serial port. The
 * data rate can be any number that is in the table above; the driver
 * is not as flexible about the speed as the Mac driver, apparently.
 * If the port is already open, it does nothing. */

int serialPortOpenByName(char *portName, int dataRate, int stopBitsType, int parityType, int dataBits,
			 int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar)
{
  int newPort= false;
  serial_port_type *sp= find_stored_serialport(portName);
  if (!sp)
    {
      if (sp_count >= MAX_SERIAL_PORTS)
	{
	  fprintf( stderr, "Error: maximum serial ports (%d) used.", MAX_SERIAL_PORTS);
	  success( false);
	  return -1;
	}
      sp= &previousSerialFiles[sp_count];
      /* save the serial port name */
      strcpy(sp->spName, portName);
      newPort= true;
    }
  else if (sp->spDescriptor >= 0)
    {
      return 0;
    }

  {
    speed_t speed= serialDecodeSpeed(dataRate);
    struct termios flags;

    /* validate arguments */
    if (speed == B0
	|| stopBitsType < 0 || stopBitsType > MAX_STOP_BITS
	|| parityType < 0 || parityType > MAX_PARITY_TYPE
	|| dataBits < 0 || dataBits > MAX_DATA_BITS
	|| inFlowCtrl < 0 || inFlowCtrl > MAX_FLOW_CTRL
	|| outFlowCtrl < 0 || outFlowCtrl > MAX_FLOW_CTRL
	|| (( inFlowCtrl == 1 || outFlowCtrl == 1 )
	    && ( xOnChar < 0 || xOnChar > 255
		 || xOffChar < 0 || xOffChar > 255 )))
      {
	fprintf(stderr, "Incorrect serial port parameters.\n");
	return portOpenFailed(sp);
      }

    /* open the device and save the file descriptor */
    if ((sp->spDescriptor= open(portName, O_RDWR|O_NONBLOCK|O_NOCTTY)) < 0)
      {
	fprintf(stderr, "Error while opening the serial port (%s).\n", portName);
	return portOpenFailed(sp);
      }

    /* save the old state */
    if (tcgetattr(sp->spDescriptor, &sp->spTermios))
      {
	fprintf(stderr, "Error while saving old state.\n");
	return portOpenFailed(sp);
      }

    /* set up the new modes */
    flags= defaultTermios;

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
	flags.c_cc[VSTART] = xOnChar;
	flags.c_cc[VSTOP]  = xOffChar;
      }

    flags.c_iflag &= ~(IXON|IXOFF|IXANY);

    if (inFlowCtrl  == 1) flags.c_iflag |= IXOFF;
    if (outFlowCtrl == 1) flags.c_iflag |= IXON;

#  if defined(CRTSCTS)
    flags.c_cflag &= ~CRTSCTS;
    if (inFlowCtrl == 2 || outFlowCtrl == 2) flags.c_cflag |= CRTSCTS;
#  else   /* not defined in IRIX!? */
    if (inFlowCtrl == 2 || outFlowCtrl == 2)
      {
	fprintf(stderr, "CRTSCTS not supported.\n");
	return portOpenFailed(sp);
      }
#  endif

    if (tcsetattr(sp->spDescriptor, TCSANOW, &flags))	/* set it NOW */
      {
	fprintf(stderr, "Error while setting terminal attributes.\n");
	return portOpenFailed(sp);
      }

    if (newPort)
      {
	++sp_count;
      }

    /* sorts the table of serial port, to ensure a reliable later retrieval. */
    qsort(previousSerialFiles, sp_count, sizeof (serial_port_type), (int(*)(const void *, const void *))serial_port_cmp);
  }

  success(true);
  return 0;
}

/* Read up to count bytes from the given serial port into the given
   byte array.  Read only up to the number of bytes in the port's
   input buffer; if fewer bytes than count have been received, do not
   wait for additional data to arrive.  Return zero if no data is
   available, else number of bytes read */

int serialPortReadInto(int portNum, int count, void *startPtr)
{
  char serialPortName[PORT_NAME_SIZE];
	
  if ((portNum < 0) || (portNum >= MAX_SERIAL_PORTS))
    {
      success(false);
      return 0;
    }
	
  make_portname_from_portnum(serialPortName, portNum);
        
  return serialPortReadIntoByName(serialPortName, count, startPtr);
}

int serialPortReadIntoByName(const char *portName, int count, void *startPtr)
{
  serial_port_type *sp= find_stored_serialport(portName);
  ssize_t bytesRead;

  /* If the serialport doesn't exist or if it is already closed. */
  if ((sp == NULL) || (sp->spDescriptor < 0))
    {
      fprintf(stderr, "Error while reading: serial port is not open.\n");
      success(false);
      return 0;
    }

  bytesRead= read(sp->spDescriptor, startPtr, (size_t)count);

  if ((ssize_t)-1 == bytesRead)
    {
      if (EAGAIN == errno)
	bytesRead= 0;
      else
	{
	  success(false);
	  return 0;
	}
    }

  success(true);
  return (int)bytesRead;
}

/* Write count bytes from the given byte array to the given serial
   port's output buffer. Return the number of bytes written. This
   implementation is synchronous: it doesn't return until the data has
   been sent. However, other implementations may return before
   transmission is complete. */

int serialPortWriteFrom(int portNum, int count, void *startPtr)
{
  char serialPortName[PORT_NAME_SIZE];
	
  if ((portNum < 0) || (portNum >= MAX_SERIAL_PORTS))
    {
      success(false);
      return 0;
    }
	
  make_portname_from_portnum(serialPortName, portNum);
        
  return serialPortWriteFromByName(serialPortName, count, startPtr);
}

int serialPortWriteFromByName(const char *portName, int count, void *startPtr)
{
  serial_port_type *sp= find_stored_serialport(portName);
  int bytesWritten;

  /* If the serialport doesn't exist or if it is already closed. */
  if ((sp == NULL) || (sp->spDescriptor < 0))
    {
      fprintf(stderr, "Error while writing: serial port is not open.\n");
      success(false);
      return 0;
    }

  bytesWritten= write(sp->spDescriptor, startPtr, (size_t)count);
        
  if ((ssize_t)-1 == bytesWritten)
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
  for (i= 0;  i < MAX_SERIAL_PORTS;  i++)
    {
      previousSerialFiles[i].spDescriptor= -1;
    }

  /* initialize our default termios structure (already 0'd) */
  defaultTermios.c_iflag= IGNBRK | IGNPAR;	/* ignore break, parity/framing errs */
  /* tcflag_t c_oflag output modes */
  /* defaultTermios.c_oflag= 0; */
  /* tcflag_t c_cflag control modes */
  defaultTermios.c_cflag= CREAD;
  /* tcflag_t c_lflag local modes */
  /* defaultTermios.c_lflag= 0; */
  /* cc_t c_cc[NCCS] control chars */
  defaultTermios.c_cc[VTIME]= 0;
  defaultTermios.c_cc[VMIN ]= 0;

  success(true);
  return 1;
}

/* return true on success */

int serialPortShutdown(void)
{
  success(true);
  return 1;
}
