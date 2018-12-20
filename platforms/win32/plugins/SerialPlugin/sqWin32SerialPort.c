/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32SerialPort.c
*   CONTENT: Serial port access
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*****************************************************************************/
#include <windows.h>
#include "sq.h"

#ifndef NO_SERIAL_PORT

/* Maximum number of serial ports supported */
#define MAX_SERIAL_PORTS 256

/* Size of the queues used by the driver */
#define  IN_QUEUE_SIZE 4096
#define OUT_QUEUE_SIZE 4096

static HANDLE serialPorts[MAX_SERIAL_PORTS];

static int isValidComm(int portNum)
{
  if(portNum <= 0 || portNum > MAX_SERIAL_PORTS || 
     serialPorts[portNum-1] == INVALID_HANDLE_VALUE)
       {
         success(false);
         return 0;
       }
  return 1;
}  

/* port number derived from "COMn" name */
int portNumberForName(const char *portName)
{
  if ((strlen(portName) < 4)
        || (strncmp(portName, "COM", 3)
              && strncmp(portName, "com", 3)))
  {
    return -1;
  } else {
    const char *p = portName + 3;
    return atoi(p);
  }
}
  
/*****************************************************************************
 Squeak Serial Port functions
 *****************************************************************************/
int serialPortClose(int portNum)
{ HANDLE port;
  /* Allow ports that aren't open to be closed		20nov98 jfb */
  if(portNum <= 0 || portNum > MAX_SERIAL_PORTS)
    { /* port number out of range */
      success(false);
      return 0;
    }
  if ((port = serialPorts[portNum-1]) != INVALID_HANDLE_VALUE)
    { PurgeComm( port, PURGE_TXABORT | PURGE_RXABORT | PURGE_TXCLEAR |  
                       PURGE_RXCLEAR ) ;
      if(!CloseHandle(port))
         printLastError(TEXT("CloseHandle failed"));
      serialPorts[portNum-1] = INVALID_HANDLE_VALUE;
    }
  return 1;
}

int serialPortCloseByName(const char *portName)
{
  int portNum = portNumberForName(portName);
  if (portNum < 0)
  { success(false);
    return 0;
  }
  return serialPortClose(portNum);
}

int serialPortMidiClockRate(int portNum, int interfaceClockRate)
{ /* ignored for now */
  return 1;
}

int serialPortOpen(int portNum, int baudRate, int stopBitsType, 
                   int parityType, int dataBits, int inFlowCtrl, 
                   int outFlowCtrl, int xOnChar, int xOffChar)
{ TCHAR name[12];
  HANDLE port;
  COMMTIMEOUTS timeouts;
  DCB dcb;

  if(portNum <= 0 || portNum > MAX_SERIAL_PORTS)
    { /* port number out of range */
      success(false);
      return 0;
    }
  if(serialPorts[portNum-1] != INVALID_HANDLE_VALUE)
    { /* port already open */
      success(false);
      return 0;
    }
  wsprintf(name,TEXT("\\\\.\\COM%d"),portNum);
  port = CreateFile(name,
      GENERIC_READ | GENERIC_WRITE,
      0,             /* comm devices must be opened with exclusive access */
      NULL,          /* no security attrs */
      OPEN_EXISTING, /* comm devices must use OPEN_EXISTING */
      0,             /* no overlapped I/O */
      NULL           /* hTemplate must be NULL for comm devices */
    );
  if(port == INVALID_HANDLE_VALUE)
    {
      printLastError(TEXT("OpenComm failed"));
      success(false);
      return 0;
    }
  /* Flush the driver */
  PurgeComm( port, PURGE_TXABORT | PURGE_RXABORT | PURGE_TXCLEAR | PURGE_RXCLEAR );

  /* Set driver buffer sizes */
  SetupComm( port,IN_QUEUE_SIZE, OUT_QUEUE_SIZE);

  /* Reset timeout constants */
  timeouts.ReadIntervalTimeout= 0xFFFFFFFF;
  timeouts.ReadTotalTimeoutMultiplier = 0;
  timeouts.ReadTotalTimeoutConstant = 0;
  timeouts.WriteTotalTimeoutMultiplier = 0;
  timeouts.WriteTotalTimeoutConstant = 0;
  SetCommTimeouts( port,&timeouts);

  /* Set communication parameters */
  ZeroMemory(&dcb, sizeof(dcb));
  dcb.DCBlength = sizeof(dcb);
  GetCommState(port, &dcb);

  dcb.BaudRate = baudRate;
  dcb.ByteSize = dataBits;
  dcb.XonChar = xOnChar;
  dcb.XoffChar = xOffChar;

  /* set stop bits */
  switch(stopBitsType) {
    case 0: dcb.StopBits = 1; break; /* 1.5 stop bits */
    case 1: dcb.StopBits = 0; break; /* 1 stop bit */
    case 2: dcb.StopBits = 2; break; /* 2 stop bits */
    default: goto errExit;
  }
  
  /* set parity */
  switch(parityType) {
    case 0: dcb.Parity = NOPARITY; break;
    case 1: dcb.Parity = ODDPARITY; break;
    case 2: dcb.Parity = EVENPARITY; break;
    default: goto errExit;
  }
  
  /* set control flow */
  dcb.fInX = FALSE;
  dcb.fDtrControl = FALSE;
	if (inFlowCtrl == 1) dcb.fInX = TRUE;  /* XOn/XOff handshaking */
	if (inFlowCtrl == 2) dcb.fDtrControl = TRUE;  /* hardware handshaking */
	dcb.fOutX = FALSE;
	dcb.fOutxCtsFlow = FALSE;
	if (outFlowCtrl == 1) dcb.fOutX = TRUE;  /* XOn/XOff handshaking */
	if (outFlowCtrl == 2) dcb.fOutxCtsFlow = TRUE;  /* hardware handshaking */

  if(!SetCommState(port, &dcb))
    {
      printLastError(TEXT("Comm configuration failed"));
      goto errExit;
    }
  serialPorts[portNum-1] = port;			/* fixed index 20nov98 jfb */
  return 1;
errExit:
  CloseHandle(port);
  success(false);
  return 0;
}

int serialPortOpenByName(char *portName, int baudRate, int stopBitsType,
                   int parityType, int dataBits, int inFlowCtrl,
                   int outFlowCtrl, int xOnChar, int xOffChar)
{
  int portNum = portNumberForName(portName);
  if (portNum < 0) {
    success(false);
    return 0;
  }
  return serialPortOpen(portNum, baudRate, stopBitsType, parityType,
			dataBits, inFlowCtrl, outFlowCtrl, xOnChar, xOffChar);
}

/* Read up to count bytes from the given serial port into the given byte array.
   Read only up to the number of bytes in the port's input buffer; if fewer bytes
   than count have been received, do not wait for additional data to arrive.
   Return zero if no data is available. */
int serialPortReadInto(int portNum, int count, void *startPtr)
{ DWORD cbReallyRead;

  if(!isValidComm(portNum)) return 0;

  if(!ReadFile(serialPorts[portNum-1],startPtr,count,&cbReallyRead,NULL))
    {
      printLastError(TEXT("ReadComm failed"));
      success(false);
      return 0;
    }
  return cbReallyRead;
}

/* Read up to count bytes from the named serial port into the given byte array.
   Read only up to the number of bytes in the port's input buffer; if fewer bytes
   than count have been received, do not wait for additional data to arrive.
   Return zero if no data is available. */
int serialPortReadIntoByName(const char *portName, int count, void *startPtr)
{
  int portNum = portNumberForName(portName);
  if (portNum < 0)
  { success(false);
    return 0;
  }
  return serialPortReadInto(portNum, count, startPtr);
}

/* Write count bytes from the given byte array to the given serial port's
   output buffer. Return the number of bytes written. This implementation is
   asynchronous: it may return before the entire packet has been sent. */
int serialPortWriteFrom(int portNum, int count, void *startPtr)
{ DWORD cbReallyWritten;

  if(!isValidComm(portNum)) return 0;
  if(!WriteFile(serialPorts[portNum-1],startPtr,count,&cbReallyWritten,NULL))
    {
      printLastError(TEXT("WriteComm failed"));
      success(false);
      return 0;
    }
  return cbReallyWritten;
}

/* Write count bytes from the named byte array to the given serial port's
   output buffer. Return the number of bytes written. This implementation is
   asynchronous: it may return before the entire packet has been sent. */
int serialPortWriteFromByName(const char *portName, int count, void *startPtr)
{
  int portNum = portNumberForName(portName);
  if (portNum < 0)
  { success(false);
    return 0;
  }
  return serialPortWriteFrom(portNum, count, startPtr);
}

int serialPortInit(void)
{
	int i;
	for(i=0; i < MAX_SERIAL_PORTS; i++)
		serialPorts[i] = INVALID_HANDLE_VALUE;
	return 1;
}

int serialPortShutdown(void)
{
	int i;
	for(i=0; i < MAX_SERIAL_PORTS; i++)
		serialPortClose(i);
	return 1;
}

#endif /* NO_SERIAL_PORT */

