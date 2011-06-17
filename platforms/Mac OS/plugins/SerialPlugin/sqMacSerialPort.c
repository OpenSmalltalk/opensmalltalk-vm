/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacSerialPort.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacSerialPort.c 1708 2007-06-10 00:40:04Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM enable 16 ports for serial, versus four, which was capped at 2?
****************************************************************************/
#include "sq.h"
#include "SerialPlugin.h"
	#include <Carbon/Carbon.h>
extern struct VirtualMachine *interpreterProxy;

/*** Constants ***/
#define INPUT_BUF_SIZE 1000

/*** Serial Ports ***/
#define MAX_PORTS 16
static short outRefNum[MAX_PORTS] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

/*** Private Functions ***/
int setHandshakeOptions(int portNum, int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar);
int serialPortSetControl(int portNum,int control, char *data);
int serialPortIsOpen(int portNum);
int serialPortNames(int portNum, char *portName, char *inName, char *outName);

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
    return false;

 }

int serialPortIsOpen(int portNum) {
	if ((portNum < 0) || (portNum >= MAX_PORTS)) return false;
	return outRefNum[portNum] != 0;
}

int serialPortSetControl(int portNum,int control, char *data) {
#pragma unused(portNum,control,data)
    return -1;
}

int serialPortNames(int portNum, char *portName, char *inName, char *outName) {
/* Fill in the user name and input and output port names for the given
   port number. Note that ports are numbered starting with zero. */
#pragma unused(portNum,portName,inName,outName)

    return false;
 }

int setHandshakeOptions(
  int portNum, int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar) {
/* Set the given port's handshaking parameters. */
#pragma unused(portNum,inFlowCtrl,outFlowCtrl,xOnChar,xOffChar)
    return false;
}
/*** Serial Port Functions ***/

EXPORT (int) serialPortClose(int portNum) {
#pragma unused(portNum)
    return false;
}

EXPORT (int) serialPortOpen(
  int portNum, int baudRate, int stopBitsType, int parityType, int dataBits,
  int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar) {
/* Open the given serial port using the given settings. The baud rate can be
   any number between about 224 and 57600; the driver will pick a clock
   divisor that will generate the closest available baud rate. */
#pragma unused(portNum,baudRate,stopBitsType,parityType,dataBits,inFlowCtrl,outFlowCtrl,xOnChar,xOffChar)
    return false;
}

EXPORT (int) serialPortReadInto(int portNum, int count, void *bufferPtr) {
/* Read up to count bytes from the given serial port into the given byte array.
   Read only up to the number of bytes in the port's input buffer; if fewer bytes
   than count have been received, do not wait for additional data to arrive.
   Return zero if no data is available. */
#pragma unused(portNum,count,bufferPtr)
    return false;
}

EXPORT (int) serialPortWriteFrom(int portNum, int count, void *bufferPtr) {
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
