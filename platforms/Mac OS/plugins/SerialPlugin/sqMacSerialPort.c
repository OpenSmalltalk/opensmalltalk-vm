/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacSerialPort.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM enable 16 ports for serial, versus four, which was capped at 2?
****************************************************************************/
#include "sq.h"
#include "SerialPlugin.h"
#if TARGET_API_MAC_CARBON
	#include <Carbon/Carbon.h>
#else
	#include <CommResources.h>
	#include <CRMSerialDevices.h>
	#include <Devices.h>
	#include <Serial.h>
	#include <Strings.h>
#endif
extern struct VirtualMachine *interpreterProxy;

/*** Constants ***/
#define INPUT_BUF_SIZE 1000

/*** Serial Ports ***/
#define MAX_PORTS 16
short inRefNum[MAX_PORTS] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
short outRefNum[MAX_PORTS] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
char inputBuffer[MAX_PORTS][INPUT_BUF_SIZE];

/*** Private Functions ***/
int setHandshakeOptions(int portNum, int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar);
#pragma export on
int serialPortSetControl(int portNum,int control, char *data);
int serialPortIsOpen(int portNum);
int serialPortNames(int portNum, char *portName, char *inName, char *outName);
#pragma export off

/* initialize/shutdown */
int serialPortInit() { return true; }
int serialPortShutdown() {
    int i;
    for(i=0;i<MAX_PORTS;i++) {
        if (serialPortIsOpen(i))
            serialPortClose(i);
    }
	return 1;
}

EXPORT (int) serialPortCount(void) {
  /* Return the number of serial ports available on this machine */

#if TARGET_API_MAC_CARBON
    return false;
#else
 	CRMRec		commRec;
 	CRMRecPtr	thisRecPtr;
 	int			count = 0;
 
	InitCRM();
 	commRec.crmDeviceType = crmSerialDevice;
 	commRec.crmDeviceID = 0;
	thisRecPtr = (CRMRecPtr) CRMSearch(&commRec);
 	while (thisRecPtr != nil) {
 		count++;
		commRec.crmDeviceID = thisRecPtr->crmDeviceID;
		thisRecPtr = (CRMRecPtr) CRMSearch(&commRec);
    }
    if (count > MAX_PORTS) count = MAX_PORTS;
 	return count;
#endif
 }

int serialPortIsOpen(int portNum) {
	if ((portNum < 0) || (portNum >= MAX_PORTS)) return false;
	return outRefNum[portNum] != 0;
}

int serialPortSetControl(int portNum,int control, char *data) {
#if TARGET_API_MAC_CARBON
    return -1;
#else
	if ((portNum < 0) || (portNum >= MAX_PORTS)) {
		return interpreterProxy->success(false); /* bad port number */
	}
	return  Control(outRefNum[portNum], control, data);
#endif
}

int serialPortNames(int portNum, char *portName, char *inName, char *outName) {
/* Fill in the user name and input and output port names for the given
   port number. Note that ports are numbered starting with zero. */

#if TARGET_API_MAC_CARBON
    return false;
#else
 	CRMRec			commRec;
 	CRMRecPtr		thisRecPtr;
 	CRMSerialPtr	serialPtr;
 	int				count = 0;
 
 	portName[0] = inName[0] = outName[0] = 0;
	if ((portNum < 0) || (portNum >= MAX_PORTS)) {
		return interpreterProxy->success(false); /* bad port number */
	}
	InitCRM();
 	commRec.crmDeviceType = crmSerialDevice;
 	commRec.crmDeviceID = 0;
	thisRecPtr = (CRMRecPtr) CRMSearch(&commRec);
 	while (thisRecPtr != nil) {
 		if (count == portNum) {
			serialPtr = (CRMSerialPtr) thisRecPtr->crmAttributes;
			CopyPascalStringToC((void *) *(serialPtr->name),portName);
			CopyPascalStringToC((void *) *(serialPtr->inputDriverName),inName);
			CopyPascalStringToC((void *) *(serialPtr->outputDriverName),outName);
                        return 0;
 		}
 		count++;
		commRec.crmDeviceID = thisRecPtr->crmDeviceID;
		thisRecPtr = (CRMRecPtr) CRMSearch(&commRec);
    }
#endif
	return 0;
 }

int setHandshakeOptions(
  int portNum, int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar) {
/* Set the given port's handshaking parameters. */
#if TARGET_API_MAC_CARBON
    return false;
#else

	SerShk handshakeOptions;
	int osErr;

	if (!serialPortIsOpen(portNum)) {
		return interpreterProxy->success(false);
	}

	handshakeOptions.fInX = false;
	handshakeOptions.fDTR = false;
	if (inFlowCtrl == 1) handshakeOptions.fInX = true;  /* XOn/XOff handshaking */
	if (inFlowCtrl == 2) handshakeOptions.fDTR = true;  /* hardware handshaking */

	handshakeOptions.fXOn = false;
	handshakeOptions.fCTS = false;
	if (outFlowCtrl == 1) handshakeOptions.fXOn = true;  /* XOn/XOff handshaking */
	if (outFlowCtrl == 2) handshakeOptions.fCTS = true;  /* hardware handshaking */

	handshakeOptions.xOn  = xOnChar;	/* XOn character */
	handshakeOptions.xOff = xOffChar;	/* XOff character */
	handshakeOptions.errs = 0;			/* clear errors mask bits */
	handshakeOptions.evts = 0;			/* clear event enable mask bits */

	osErr = Control(outRefNum[portNum], 14, &handshakeOptions);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}
#endif
	return 0;
}
/*** Serial Port Functions ***/

EXPORT (int) serialPortClose(int portNum) {
#if TARGET_API_MAC_CARBON
    return false;
#else
	int osErr;

	if (!serialPortIsOpen(portNum)) {
		return 0;  /* already closed */
	}
	osErr = KillIO(outRefNum[portNum]);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}
	osErr = CloseDriver(inRefNum[portNum]);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}
	osErr = CloseDriver(outRefNum[portNum]);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}

	inRefNum[portNum] = 0;
	outRefNum[portNum] = 0;
#endif
	return 0;
}

EXPORT (int) serialPortOpen(
  int portNum, int baudRate, int stopBitsType, int parityType, int dataBits,
  int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar) {
/* Open the given serial port using the given settings. The baud rate can be
   any number between about 224 and 57600; the driver will pick a clock
   divisor that will generate the closest available baud rate. */
#if TARGET_API_MAC_CARBON
    return false;
#else

	short int options, baudRateParam;
	char userName[256], inName[256], outName[256];
	int osErr;

	if ((portNum < 0) || (portNum >= MAX_PORTS) || serialPortIsOpen(portNum)) {
		return interpreterProxy->success(false); /* bad port number or port already open */
	}

	options = baud9600;
	switch (stopBitsType) {
	case 0:
		options += stop15;
		break;
	case 1:
		options += stop10;
		break;
	case 2:
		options += stop20;
		break;
	default:
		return interpreterProxy->success(false);
	}

	switch (parityType) {
	case 0:
		options += noParity;
		break;
	case 1:
		options += oddParity;
		break;
	case 2:
		options += evenParity;
		break;
	default:
		return interpreterProxy->success(false);
	}

	switch (dataBits) {
	case 5:
		options += data5;
		break;
	case 6:
		options += data6;
		break;
	case 7:
		options += data7;
		break;
	case 8:
		options += data8;
		break;
	default:
		return interpreterProxy->success(false);
	}

	serialPortNames(portNum, userName, inName, outName);
	CopyCStringToPascal((const char *)outName,(unsigned char *) outName);
	osErr = OpenDriver((unsigned char *)outName, &outRefNum[portNum]);
	if (osErr != noErr) {
		return interpreterProxy->success(false);
	}
	CopyCStringToPascal((const char *)inName,(unsigned char *)inName);
	osErr = OpenDriver((unsigned char *)inName, &inRefNum[portNum]);
	if (osErr != noErr) {
		CloseDriver(outRefNum[portNum]);
		return interpreterProxy->success(false);
	}

	/* set the handshaking options */
	setHandshakeOptions(portNum, inFlowCtrl, outFlowCtrl, xOnChar, xOffChar);

	/* install a larger input buffer */
	osErr = SerSetBuf(inRefNum[portNum], &inputBuffer[portNum][0], INPUT_BUF_SIZE);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}

	/* set data bits, parity type, and stop bits */
	osErr = SerReset(outRefNum[portNum], options);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}

	/* set the baud rate (e.g., the value 9600 gives 9600 baud) */
	baudRateParam = baudRate;
	osErr = Control(outRefNum[portNum], 13, &baudRateParam);
	if (osErr != noErr) {
		interpreterProxy->success(false);
	}

	if (interpreterProxy->failed()) {
		CloseDriver(inRefNum[portNum]);
		CloseDriver(outRefNum[portNum]);
		inRefNum[portNum] = 0;
		outRefNum[portNum] = 0;
	}
#endif
	return 0;
}

EXPORT (int) serialPortReadInto(int portNum, int count, int bufferPtr) {
/* Read up to count bytes from the given serial port into the given byte array.
   Read only up to the number of bytes in the port's input buffer; if fewer bytes
   than count have been received, do not wait for additional data to arrive.
   Return zero if no data is available. */
#if TARGET_API_MAC_CARBON
    return false;
#else

	long int byteCount;
	int osErr;

	if (!serialPortIsOpen(portNum)) {
		return interpreterProxy->success(false);
	}

	osErr = SerGetBuf(inRefNum[portNum], &byteCount);  /* bytes available */
	if (osErr != noErr) {
		return interpreterProxy->success(false);
	}

	if (byteCount > count) byteCount = count;  /* read at most count bytes */
	osErr = FSRead(inRefNum[portNum], &byteCount, (char *) bufferPtr);
	if (osErr != noErr) {
		return interpreterProxy->success(false);
	}
	return byteCount;
#endif
}

EXPORT (int) serialPortWriteFrom(int portNum, int count, int bufferPtr) {
/* Write count bytes from the given byte array to the given serial port's
   output buffer. Return the number of bytes written. This implementation is
   synchronous: it doesn't return until the data has been sent. However, other
   implementations may return before transmission is complete. */

	long int byteCount = count;
	int osErr;

	if (!serialPortIsOpen(portNum)) {
		return interpreterProxy->success(false);
	}

	osErr = FSWrite(outRefNum[portNum], &byteCount, (char *) bufferPtr);
	if (osErr != noErr) {
		return interpreterProxy->success(false);
	}
	return byteCount;
}
