/* unixSerialPort2Ops.c -- Scratch operations for unix based OSes. Support
 * for SerialPort2 primitives under Unix, including OSX and Linux.
 *
 * 
 *   Copyright (C) 2011 Massachusetts Institute of Technology
 *   All rights reserved.
 *   
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 */

#include "ScratchPlugin.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

// support for systems with a single hardware flow control bit
// on such systems setting hardware handshaking for input sets it for output as well
#ifndef CRTS_IFLOW
# define CRTS_IFLOW CRTSCTS
#endif
#ifndef CCTS_OFLOW
# define CCTS_OFLOW CRTSCTS
#endif


// globals
#define PORT_COUNT 32
static int gFileDescr[PORT_COUNT] = {			// file descriptors for open serial ports
	-1, -1, -1, -1, -1, -1, -1, -1,				// the portNum kept by Squeak is an index
	-1, -1, -1, -1, -1, -1, -1, -1,				// into this array. -1 marks unused entries.
	-1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1};
static struct termios gOrigTermios[PORT_COUNT]; // original termios settings for open ports

#define PRIM_FAILED -1

// helper function declarations
int FileDescrForEntry(int portNum);
int OpenPortNamed(const char *bsdPath, int baudRate, int entryIndex);
int isPrefix(char *prefix, char *s);
int isSerialPortDev(char *s);

int SerialPortCount(void) {
	DIR						*dirPtr;
	struct dirent	*entryPtr;
	int						cnt = 0;

	if ((dirPtr = opendir("/dev")) == NULL) return 0;

	while ((entryPtr = readdir(dirPtr)) != NULL) {
		if (isSerialPortDev(entryPtr->d_name)) cnt++;
	}

	closedir(dirPtr);
	return cnt;
}

// Find the name of the given port number. Fill in bsdPath if successful.
// Otherwise, make bsdPath be the empty string.
void SerialPortName(int portIndex, char *bsdPath, int maxPathSize) {
	DIR						*dirPtr;
	struct dirent	*entryPtr;
	int						cnt = 0;

	*bsdPath = '\0';	// result is the empty string if port not found

	if (portIndex < 1) return;
	if ((dirPtr = opendir("/dev")) == NULL) return;

	while ((entryPtr = readdir(dirPtr)) != NULL) {
		if (isSerialPortDev(entryPtr->d_name)) cnt++;
		if (cnt == portIndex) {
			strncat(bsdPath, "/dev/", maxPathSize);
			strncat(bsdPath, entryPtr->d_name, maxPathSize);
			closedir(dirPtr);
			return;
		}
	}

	closedir(dirPtr);
}

int SerialPortOpenPortNamed(char *portName, int baudRate) {
	int entryIndex;

	// scan for first free entry
	for (entryIndex = 0; entryIndex < PORT_COUNT; entryIndex++) {
		if (gFileDescr[entryIndex] == -1) break;
	}
	if (entryIndex >= PORT_COUNT) return PRIM_FAILED; // no free entry

	if (!OpenPortNamed(portName, baudRate, entryIndex)) return PRIM_FAILED;
	return entryIndex;
}

void SerialPortClose(int portNum) {
	int fDescr;

	if ((fDescr = FileDescrForEntry(portNum)) < 0) return; // already closed

	// restore the serial port settings to their original state
	tcsetattr(fDescr, TCSANOW, &gOrigTermios[portNum]);
	close(fDescr);
	gFileDescr[portNum] = -1;
}

int SerialPortIsOpen(int portNum) {
	return FileDescrForEntry(portNum) != -1;
}

int SerialPortRead(int portNum, char *bufPtr, int bufSize) {
	int fDescr, count = 0;

	if ((fDescr = FileDescrForEntry(portNum)) < 0) return 0;

	count = read(fDescr, bufPtr, bufSize);
	if (count < 0) return 0; // read error
	return count;
}

int SerialPortWrite(int portNum, char *bufPtr, int bufSize) {
	int fDescr, count = 0;

	if ((fDescr = FileDescrForEntry(portNum)) < 0) return 0;

	count = write(fDescr, bufPtr, bufSize);
	if (count < 0) return 0; // write error
	return count;
}

// Port options for SetOption/GetOption:
//	1. baud rate
//	2. data bits
//	3. stop bits
//	4. parity type
//	5. input flow control type
//	6. output flow control type
//	20-25: handshake line bits (DTR, RTS, CTS, DSR, CD, RD)

int SerialPortSetOption(int portNum, int optionNum, int newValue) {
	int fDescr, handshake;
	struct termios options;

	if ((fDescr = FileDescrForEntry(portNum)) < 0) return PRIM_FAILED;
	if (tcgetattr(fDescr, &options) == -1) return PRIM_FAILED;

	switch (optionNum) {
	case 1: // baud rate
		if (cfsetspeed(&options, newValue) == -1) return PRIM_FAILED;
		break;
	case 2: // # of data bits
		switch(newValue) {
		case 5:
			options.c_cflag = (options.c_cflag & ~CSIZE) | CS5;
			break;
		case 6:
			options.c_cflag = (options.c_cflag & ~CSIZE) | CS6;
			break;
		case 7:
			options.c_cflag = (options.c_cflag & ~CSIZE) | CS7;
			break;
		case 8:
			options.c_cflag = (options.c_cflag & ~CSIZE) | CS8;
			break;
		}
		break;
	case 3: // 1 or 2 stop bits
		if (newValue > 1) options.c_cflag |= CSTOPB;		// two stop bits
		else options.c_cflag &= ~CSTOPB;					// one stop bit
		break;
	case 4: // parity
		options.c_cflag &= ~(PARENB | PARODD);						// no parity
		if (newValue == 1) options.c_cflag |= (PARENB | PARODD);	// odd parity
		if (newValue == 2) options.c_cflag |= PARENB;				// even parity
		break;
	case 5: // input flow control
		options.c_iflag &= ~IXOFF;							// disable xoff input flow control
		options.c_cflag &= ~CRTS_IFLOW;						// disable RTS (hardware) input flow control
		if (newValue == 1) options.c_iflag |= IXOFF;		// enable xoff input flow control
		if (newValue == 2) {
			options.c_cflag |= CRTS_IFLOW;					// enable RTS (hardware) input flow control
			if (CRTS_IFLOW == CCTS_OFLOW) {					// on systems with a single hardware flow control bit: 
				options.c_iflag &= ~(IXON | IXOFF);			//   disable xon/xoff flow control
			}
		}
		break;
	case 6: // output flow control
		options.c_iflag &= ~IXON;							// disable xon output flow control
		options.c_cflag &= ~CCTS_OFLOW;						// disable CTS (hardware) output flow control
		if (newValue == 1) options.c_iflag |= IXON;			// enable xon output flow control
		if (newValue == 2) {
			options.c_cflag |= CCTS_OFLOW;					// enable CTS (hardware) output flow control
			if (CRTS_IFLOW == CCTS_OFLOW) {					// on systems with a single hardware flow control bit: 
				options.c_iflag &= ~(IXON | IXOFF);			//   disable xon/xoff flow control
			}
		}
		break;

	case 20: // set DTR line state
		if (ioctl(fDescr, TIOCMGET, &handshake) == -1) return PRIM_FAILED;
		handshake = newValue ? (handshake | TIOCM_DTR) : (handshake & ~TIOCM_DTR);
		if (ioctl(fDescr, TIOCMSET, &handshake) == -1) return PRIM_FAILED;
		break;
	case 21: // set RTS line state
		if (ioctl(fDescr, TIOCMGET, &handshake) == -1) return PRIM_FAILED;
		handshake = newValue ? (handshake | TIOCM_RTS) : (handshake & ~TIOCM_RTS);
		if (ioctl(fDescr, TIOCMSET, &handshake) == -1) return PRIM_FAILED;
		break;
	}
	if (tcsetattr(fDescr, TCSANOW, &options) == -1) return PRIM_FAILED;
	return 0;
}

int SerialPortGetOption(int portNum, int optionNum) {
	int fDescr, handshake = -1;
	struct termios options;

	if ((fDescr = FileDescrForEntry(portNum)) < 0) return PRIM_FAILED;
	if (tcgetattr(fDescr, &options) == -1) return PRIM_FAILED;
	if (ioctl(fDescr, TIOCMGET, &handshake) == -1) return PRIM_FAILED;

	switch (optionNum) {
	case 1: return (int) cfgetispeed(&options);
	case 2:
		if ((options.c_cflag & CSIZE) == CS5) return 5;
		if ((options.c_cflag & CSIZE) == CS6) return 6;
		if ((options.c_cflag & CSIZE) == CS7) return 7;
		if ((options.c_cflag & CSIZE) == CS8) return 8;
		return PRIM_FAILED;
	case 3: return (options.c_cflag & CSTOPB) ? 2 : 1;
	case 4:
		if (!(options.c_cflag & PARENB)) return 0;
		return (options.c_cflag & PARODD) ? 1 : 2;
	case 5:
		if (options.c_iflag & IXOFF) return 1;
		if (options.c_cflag & CRTS_IFLOW) return 2;
		return 0;
	case 6:
		if (options.c_iflag & IXON) return 1;
		if (options.c_cflag & CCTS_OFLOW) return 2;
		return 0;

	case 20: return (handshake & TIOCM_DTR) > 0;
	case 21: return (handshake & TIOCM_RTS) > 0;
	case 22: return (handshake & TIOCM_CTS) > 0;
	case 23: return (handshake & TIOCM_DSR) > 0;
	case 24: return (handshake & TIOCM_CD) > 0;
	case 25: return (handshake & TIOCM_RI) > 0;
	}
	return PRIM_FAILED;
}

// ***** helper functions *****

// Return the file descriptor for the given entry or -1 if either the
// given port number (index) is out of range or the port is not open.
int FileDescrForEntry(int portNum) {
	if ((portNum < 0) || (portNum >= PORT_COUNT)) return PRIM_FAILED;
	return gFileDescr[portNum];
}

// Given the path to a serial device, open the device and configure it for
// using given entryIndex. Answer 1 if the operation succeeds, 0 if it fails.
int OpenPortNamed(const char *bsdPath, int baudRate, int entryIndex) {
	int fDescr = -1;
	struct termios options;

	// open the serial port read/write with no controlling terminal; don't block
	fDescr = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
	if (fDescr == -1) {
		printf("Error opening serial port %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}

	// request exclusive access to the port
	if (ioctl(fDescr, TIOCEXCL) == -1) {
		printf("Error setting TIOCEXCL on %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}

	// save port settings so we can restore them later
	if (tcgetattr(fDescr, &gOrigTermios[entryIndex]) == -1) {
		printf("Error getting attributes %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}

	// port settings are made by modifying a copy of the termios struct
	// and then calling tcsetattr() to make those changes take effect.
	options = gOrigTermios[entryIndex];

	// set the baud rate
	if (cfsetspeed(&options, baudRate) == -1) {
		printf("Error setting speed %d %s - %s(%d).\n", baudRate, bsdPath, strerror(errno), errno);
		goto error;
	}

	// set raw input (non-canonical) mode, with writes not blocking.
	cfmakeraw(&options);
	options.c_cc[VMIN] = 0;
	options.c_cc[VTIME] = 0;

	// install the new port settings
	if (tcsetattr(fDescr, TCSANOW, &options) == -1) {
		printf("Error setting attributes %s - %s(%d).\n", bsdPath, strerror(errno), errno);
		goto error;
	}
	gFileDescr[entryIndex] = fDescr;
	return 1; // success!

error:
	if (fDescr != -1) close(fDescr);
	return 0;
}

int isSerialPortDev(char *s) {
	return isPrefix("ttyusb", s) || isPrefix("ttyAMA", s);
}

int isPrefix(char *prefix, char *s) {
	int prefixC, c;
	while (1) {
		prefixC = *prefix++;
		c = *s++;
		if (prefixC == 0) return 1; // match!
		if (c == 0) return 0; // s is shorter than prefix
		if (c != prefixC) {
			if (('a' <= c) && (c <= 'z')) c -= 32;
			if (('a' <= prefixC) && (prefixC <= 'z')) prefixC -= 32;
			if (c != prefixC) return 0; // non-match
		}
	}
}
