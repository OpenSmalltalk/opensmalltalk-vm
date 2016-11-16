/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32MIDI.c
*   CONTENT: Minimal MIDI interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*     1) For MIDI output the MIDI mapper is reported as first device
*        (e.g., portNum = 0) making it the default device.
*     2) The VM level scheduler uses a heap as output buffer.
*
*****************************************************************************/
#include <windows.h>
#include <mmsystem.h>
#include "sq.h"
#include "MIDIPlugin.h"

#ifndef NO_MIDI

#ifndef STACK_SIZE_PARAM_IS_A_RESERVATION
# define STACK_SIZE_PARAM_IS_A_RESERVATION 0x00010000
#endif

/*** MIDI Parameters (used with sqMIDIParameter function) ***/

#define sqMIDIInstalled				1
/* Read-only. Return 1 if a MIDI driver is installed, 0 if not.
   On OMS-based MIDI drivers, this returns 1 only if the OMS
   system is properly installed and configured. */

#define sqMIDIVersion				2
/* Read-only. Return the integer version number of this MIDI driver.
   The version numbering sequence is relative to a particular driver.
   That is, version 3 of the Macintosh MIDI driver is not necessarily
   related to version 3 of the Win95 MIDI driver. */

#define sqMIDIHasBuffer				3
/* Read-only. Return 1 if this MIDI driver has a time-stamped output
   buffer, 0 otherwise. Such a buffer allows the client to schedule
   MIDI output packets to be sent later. This can allow more precise
   timing, since the driver uses timer interrupts to send the data
   at the right time even if the processor is in the midst of a
   long-running Squeak primitive or is running some other application
   or system task. */

#define sqMIDIHasDurs				4
/* Read-only. Return 1 if this MIDI driver supports an extended
   primitive for note-playing that includes the note duration and
   schedules both the note-on and the note-off messages in the
   driver. Otherwise, return 0. */

#define sqMIDICanSetClock			5
/* Read-only. Return 1 if this MIDI driver''s clock can be set
   via an extended primitive, 0 if not.*/

#define sqMIDICanUseSemaphore		6
/* Read-only. Return 1 if this MIDI driver can signal a semaphore
   when MIDI input arrives. Otherwise, return 0. If this driver
   supports controller caching and it is enabled, then incoming
   controller messages will not signal the semaphore. */

#define sqMIDIEchoOn				7
/* Read-write. If this flag is set to a non-zero value, and if
   the driver supports echoing, then incoming MIDI events will
   be echoed immediately. If this driver does not support echoing,
   then queries of this parameter will always return 0 and
   attempts to change its value will do nothing. */

#define sqMIDIUseControllerCache	8
/* Read-write. If this flag is set to a non-zero value, and if
   the driver supports a controller cache, then the driver will
   maintain a cache of the latest value seen for each MIDI controller,
   and control update messages will be filtered out of the incoming
   MIDI stream. An extended MIDI primitive allows the client to
   poll the driver for the current value of each controller. If
   this driver does not support a controller cache, then queries
   of this parameter will always return 0 and attempts to change
   its value will do nothing. */

#define sqMIDIEventsAvailable		9
/* Read-only. Return the number of MIDI packets in the input queue. */

#define sqMIDIFlushDriver			10
/* Write-only. Setting this parameter to any value forces the driver
   to flush its I/0 buffer, discarding all unprocessed data. Reading
   this parameter returns 0. Setting this parameter will do nothing
   if the driver does not support buffer flushing. */

#define sqMIDIClockTicksPerSec		11
/* Read-only. Return the MIDI clock rate in ticks per second. */

#define sqMIDIHasInputClock			12
/* Read-only. Return 1 if this MIDI driver timestamps incoming
   MIDI data with the current value of the MIDI clock, 0 otherwise.
   If the driver does not support such timestamping, then the
   client must read input data frequently and provide its own
   timestamping. */


/***************************************************************************
 Driver internals
 ***************************************************************************/

#define NoteOnCmd		0x90
#define NoteOffCmd		0x80
#define PgmChngCmd		0xC0
#define ControlCmd		0xB0
#define PolyPressCmd	0xA0
#define ChanPressCmd	0xD0
#define PchWheelCmd		0xE0
#define SysExCmd		0xF0

/* The length of meta events for easier processing */
static int midiMetaEventLengths[16] = {
 -1, /* 0xF0: System Exclusive -> read until (including) next status byte */
  2, /* 0xF1: MTC Quarter Frame; 2 bytes */
  3, /* 0xF2: Song Position Pointer; 3 bytes */
  2, /* 0xF3: Song Select; 2 bytes */
  0, /* 0xF4: Unassigned -> read up to next status byte */
  0, /* 0xF5: Unassigned -> read up to next status byte */
  1, /* 0xF6: Tune Request; 1 byte */
  1, /* 0xF7: End of System Exclusive; should not happen */
  1, /* 0xF8: MIDI Clock; 1 byte */
  0, /* 0xF9: Unassigned -> read up to next status byte */
  1, /* 0xFA: MIDI Start; 1 byte */
  1, /* 0xFB: MIDI Continue; 1 byte */
  1, /* 0xFC: MIDI Stop; 1 byte */
  0, /* 0xFD: Unassigned -> read up to next status byte */
  1, /* 0xFE: Active Sense; 1 byte */
  1  /* 0xFF: Reset; 1 byte */
};

/***************************************************************
 * Global state variabless
 */
static int isControllerCaching = 0;
static int isEchoEnabled = 0;

/***************************************************************
 * Controller value caches -- This is the minimum complement
 * A "larger" driver would cache 128*16 controllers and 128*16 key pressures
 */
typedef struct sqControllerCache {
  unsigned char sqControllers[128];  /* Controller value table */
  unsigned char sqKeyPressures[128]; /* Polyphonic key pressure table */
  unsigned char sqChanPressures[16]; /* Channel pressure value table */
  int sqPitchBend[16];               /* The value of the pitch wheel */
} sqControllerCache;

/***************************************************************
 Global definitions
 ***************************************************************/

/* MAX_MIDI_BUFFER defines the maximum number of midi packets we handle.*/
#define MAX_MIDI_BUFFER 1024
#define MAX_SYSEX_BUFFER 512

/* Maximum number of devices supported */
#define MAX_DEVICES 32

/* Flags for midi port */
#define MIDI_IN_DEVICE 1
#define MIDI_OUT_DEVICE 2
#define PENDING_SYSEX 4

/***************************************************************
 The MIDI port structure 
 ***************************************************************/
typedef struct sqMidiOutEvent {
  DWORD data;
  DWORD stamp;
} sqMidiOutEvent;

typedef struct sqMidiInEvent {
  DWORD data;
  DWORD stamp;
} sqMidiInEvent;

typedef struct sqMidiPort {
  HANDLE handle;    /* The actual MIDI in/out handle */
  DWORD flags;      /* Flags (including direction and stats) */
  TCHAR name[MAXPNAMELEN+1]; /* This port's name */

  /*************************************/
  /* output stuff                      */
  /*************************************/

  /* buffer for pending short messages */
  unsigned char  pendingCommand[4];
  DWORD pendingLength;    /* current length of the pending command */
  DWORD pendingSize;      /* Remaining data of the pending command */
  DWORD pendingStamp;     /* Stamp of the pending command */

  /* events used during output */
  HANDLE outBufferMutex;  /* we better synchronize access to the output buffer */
  HANDLE outBufferData;   /* signaled whenever the first event changes */
  HANDLE schedulerThread; /* The thread for scheduling MIDI messages */

  /* output buffer */
  sqMidiOutEvent *outBuffer;  /* output buffer */
  DWORD nOutEvents;           /* items in buffer */

  /* sysex buffer */
  unsigned char *sysExBuffer; /* sysex buffer */
  DWORD sysExLength;          /* length of sysex buffer */

  /*************************************/
  /* input stuff                       */
  /*************************************/

  /* buffer for pending input */
  DWORD pendingInputStamp;    /* The stamp of the pending input */
  DWORD pendingInputData;     /* pending input data */

  /* input buffer */
  int   semaphore;  /* The Smalltalk semaphore to signal on input */
  sqMidiInEvent *inBuffer;    /* input buffer */
  DWORD inBufferStart;        /* read start   */
  DWORD inBufferEnd;          /* read end     */

  /* controller cache */
  sqControllerCache cache;
} sqMidiPort;

/* The number of MIDI devices for input and output */
static int midiOutNumDevices = 0;
static int midiInNumDevices = 0;

/* The MIDI ports */
static sqMidiPort *(midiPorts[MAX_DEVICES]);

/* Input event and thread */
static HANDLE midiInputEvent  = (HANDLE) 0;
static HANDLE midiInputThread = (HANDLE) 0;

/* a list of MIDIHDRs which might be recycled when sending SysEx messages */
static MIDIHDR *midiHeaderList = NULL;


#ifndef NDEBUG
#define DBGPRINTF warnPrintf
#else
#define DBGPRINTF
#endif


/*************************************************************************************
 Heap functions:
   For VM level scheduling we use a heap structure. The idea is that events
   coming in may not be ordered (since they will scheduled by the VM) and
   that completely sorting the output buffer takes longer than the incremental
   update. Note that the actual implementation below relies on one-based arrays
   (yes -- I've taken this code from my Smalltalk class Heap ;-)) AR
 *************************************************************************************/

/* adjust the heap after adding an element */
static void midiOutHeapUpFrom(sqMidiPort *port,int index)
{ sqMidiOutEvent *buf, event, temp;
  int j, k, size;

  buf = port->outBuffer;
  size = port->nOutEvents;
  /* HACK! Start from one-based indexes */
  buf--;
  /* Start checking the heap */
  if(index < 1) return;
  k = index;
  event = buf[index];
  while(k > 1)
    {
      j = k / 2;
      temp = buf[j];
      if(event.stamp >= temp.stamp) break; /* heap ok */
      buf[k] = temp;
      k = j;
    }
  buf[k] = event;
}

/* Remove the first element from the heap and adjust it. */
static void midiOutHeapRemoveFirst(sqMidiPort *port)
{ sqMidiOutEvent *buf, event;
  int j,k,n, size;

  buf = port->outBuffer;
  size = --port->nOutEvents;
  /* HACK! Start from one-based indexes */
  buf--;
  /* replace top item in heap with last one */
  event = buf[size+1];
  /* adjust heap */
  n = size / 2;
  k = 1;
  while(k <= n) {
    j = 2*k;
    if(j < size && (buf[j+1].stamp < buf[j].stamp)) j++;
    buf[k] = buf[j];
    k = j;
  };
  buf[k] = event;
  midiOutHeapUpFrom(port,k);
}

/**************************************************************************************
   midiInNotifyThread: This function runs an endless loop and whenever 
                       midiInputEvent is signaled it forwards the change in state
                       to the associated Squeak semaphore
  *************************************************************************************/
static DWORD WINAPI midiNotifyThread(DWORD ignored)
{ int i;
  sqMidiPort *port;

  while(1)
    {
      WaitForSingleObject(midiInputEvent, INFINITE);
      for(i=0;i<MAX_DEVICES;i++)
        {
          port = midiPorts[i];
          if(port)
            if( (port->inBufferStart != port->inBufferEnd) && port->semaphore)
              synchronizedSignalSemaphoreWithIndex(port->semaphore);
        }
    }
  /* not reached */
  return 0;
}

/**************************************************************************************
   midiInCallback: The callback function called whenever a midi message is received.
                   This function is called from a different (real-time) thread and thus 
                   must be *very* cautious of what function it calls. We do only call
                   two of the functions allowed from within MIDI callbacks, e.g.,
                   midiOutShortMsg and SetEvent
  *************************************************************************************/
static void CALLBACK midiInCallback(HMIDIIN  hMidiIn,UINT  uMsg, DWORD_PTR  dwUser,
                             DWORD  dwParam1, DWORD  dwParam2)
{ int cmd, cmdLen;
  sqMidiInEvent *dst;
  int channel, value, value2;
  DWORD data;
  sqMidiPort *port = (sqMidiPort*)dwUser;

  /* SysEx messages are ignored (sent with uMsg == MIM_LONG_DATA) */
  if(uMsg != MIM_DATA) return;
  /* Short Message:
          dwParam1: DWORD packed command with first byte of the message in the low-order byte.
          dwParam2: msecs since midiInStart() has been called
     MIDI messages received from a MIDI input port have running status disabled; 
     each message is expanded to include the MIDI status byte. 
     This message is not sent when a MIDI system-exclusive message is received. */
  cmd = dwParam1 & 0xF0;
#if 0
  /* Echoing should go here but we don't have it yet */
  if(isEchoEnabled)
    for(i=0;i<MAX_DEVICES;i++)
      if(midiPorts[i])
        if(midiPorts[i]->flags & MIDI_OUT_DEVICE)
          midiOutShortMsg((HMIDIOUT)(midiPorts[i]->handle), dwParam1);
#endif
  if (isControllerCaching)
    { /* Cache controller values in the driver */
      switch(cmd) {
        case ControlCmd: /* Read a control command */
          channel = (dwParam1 >> 8) & 0xFF;
          value =  (dwParam1 >> 16) & 0xFF;
          port->cache.sqControllers[channel] = value;
          return;
        case PchWheelCmd: /* Read a pitch wheel change */
          channel = dwParam1 & 0x0F;
          value = (dwParam1 >> 8) & 0xFF;
          value2 = (dwParam2 >> 16) & 0xFF;
          port->cache.sqPitchBend[channel] = (value2 << 7) + value;
          return;
        case PolyPressCmd: /* Read polyphonic key pressure */
          channel = (dwParam1 >> 8) & 0xFF;
          value =  (dwParam1 >> 16) & 0xFF;
          port->cache.sqKeyPressures[channel] = value;
          return;
        case ChanPressCmd: /* Read channel key pressure */
          channel = dwParam1 & 0x0F;
          value = (dwParam1 >> 8) & 0xFF;
          port->cache.sqKeyPressures[channel] = value;
          return;
        default: /* do nothing */
          break;
      };
    }
  if(cmd == SysExCmd)
    cmdLen = midiMetaEventLengths[dwParam1 & 0x0F];
  else if(cmd == PgmChngCmd || cmd == ChanPressCmd)
    /* all but program change and channel pressure have two data bytes */
    cmdLen = 2;
  else
    cmdLen = 3;
  /* compute data word; at most 3 bytes plus 1 byte for length */
  data = dwParam1 | (cmdLen << 24);
  /* store data and stamp in the buffer */
  dst = port->inBuffer + port->inBufferEnd;
  dst->data = data;
  dst->stamp = dwParam2;
  port->inBufferEnd++;
  if(port->inBufferEnd == MAX_MIDI_BUFFER)
    port->inBufferEnd = 0; /* wrap around */
  /* Notify another thread that something has changed.
     We do *not* call synchronousSignalSemaphoreWithIndex
     because this may suspend the current thread.
     Even more, SetEvent is one of the few functions which
     can be called from the MIDI callback function without
     worrying for timing problems. */
  if(cmdLen && port->semaphore)
    SetEvent(midiInputEvent);
}        

/*************************************************************************************
 midiScheduler: This function simulates a VM-level scheduler for MIDI messages.
                It is run at a high priority so we better not waste a lot of time
                in here.
 *************************************************************************************/
static DWORD WINAPI midiScheduler(sqMidiPort *port)
{ sqMidiOutEvent *evt;
  int delay;

  /* we always read the first event */
  evt = &(port->outBuffer[0]);
  while(1) {
    /* Wait until we have access to the out buffer */
    WaitForSingleObject(port->outBufferMutex, INFINITE);
    /* check if there are any events at all */
    if(port->nOutEvents)
      delay = port->outBuffer[0].stamp - timeGetTime();
    else
      delay = 0x7FFFFFFF;
    ReleaseMutex(port->outBufferMutex);

    /* Wait until the next event gets scheduled or until
       an event gets to the start of the queue */
    if(delay > 0)
      WaitForSingleObject(port->outBufferData, delay);

    /* Schedule all events currently in range. */
    WaitForSingleObject(port->outBufferMutex, INFINITE);
    while(port->nOutEvents) {
      /* check if event is in range */
      delay = evt->stamp - timeGetTime();
      if(delay > 0) break; /* not in range */
      /* send the command */
      midiOutShortMsg((HMIDIOUT)(port->handle), evt->data);
      /* and adjust the heap */
      midiOutHeapRemoveFirst(port);
    }
    ReleaseMutex(port->outBufferMutex);
    /* All events have been sent */
  }  
}

/*************************************************************************************
 scheduleShortMessage: Schedule a short messgage in the appropriate MIDI port
 *************************************************************************************/
int scheduleShortMessage(sqMidiPort *port, DWORD data, DWORD stamp)
{ int doSignal = 0;

  if((int)(stamp - timeGetTime()) <= 0)
    return midiOutShortMsg((HMIDIOUT) port->handle, data);

  if(port->nOutEvents == MAX_MIDI_BUFFER)
    return 0; /* not scheduled */
  if(WaitForSingleObject(port->outBufferMutex, 5000) == WAIT_TIMEOUT)
    {
#ifndef NO_WARNINGS
      warnPrintf(TEXT("MIDI: Output busy for more than 5 seconds.\n"));
#endif
      return 0;
    }
  /* signal if there were no events before or if the new command comes first */
  if(port->nOutEvents == 0 || (port->outBuffer[0].stamp > stamp))
    doSignal = 1;
  /* add the data */
  port->outBuffer[port->nOutEvents].data = data;
  port->outBuffer[port->nOutEvents].stamp = stamp;
  port->nOutEvents++;
  /* adjust the heap 
     NOTE: We're using 1-based indexes here! */
  midiOutHeapUpFrom(port, port->nOutEvents);
  ReleaseMutex(port->outBufferMutex);
  if(doSignal)
    SetEvent(port->outBufferData);
  return 1;
}

/*************************************************************************************
 sendLongMidiData: Send a MIDI command not fitting into 4 bytes. (e.g. a SysEx message)
 *************************************************************************************/
static void sendLongMidiData(HMIDIOUT midiOutPort, char *data, int numBytes)
{ MIDIHDR *header = NULL;

  /* recycle headers if possible */
  if(midiHeaderList)
    {
      header = midiHeaderList;
      while(header)
        if(header->dwFlags & MHDR_DONE)
          break;
        else
          header = (MIDIHDR*)header->dwUser;
    }
   if(!header)
     { /* allocate new header */
       header = GlobalLock(GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE | GMEM_ZEROINIT, sizeof(MIDIHDR)));
       header->dwUser = (DWORD_PTR)midiHeaderList;
       midiHeaderList = header;
     }
   if(header->lpData)
     { /* old data in header */
       GlobalUnlock(GlobalHandle(header->lpData));
       GlobalFree(GlobalHandle(header->lpData));
     }
   /* copy data */
   header->lpData = GlobalLock(GlobalAlloc(GMEM_MOVEABLE | GMEM_SHARE, numBytes));
   header->dwBufferLength = numBytes;
   header->dwFlags &= ~MHDR_DONE;
   MoveMemory(header->lpData, data, numBytes);
   /* and send data to the driver */
   midiOutPrepareHeader(midiOutPort, header, sizeof(MIDIHDR));
   midiOutLongMsg(midiOutPort, header, sizeof(MIDIHDR));
}

/*************************************************************************************
 startSysExCommand: Try to read a complete SysEx message from the (smalltalk) source.
                    Return the number of bytes actually read or -1 on error.
                    The function may set the PENDING_SYSEX flag in the port if
                    there is not enough data to complete the SysEx.
 *************************************************************************************/
int startSysExCommand(sqMidiPort *port, unsigned char *srcPtr, int count)
{ /* Start a variable length Sysex command */
  unsigned char *sxBuf = port->sysExBuffer;
  int n = 0;
  /* clamp count to an appropriate range */
  if(count > MAX_SYSEX_BUFFER) count = MAX_SYSEX_BUFFER;
  /* copy the first (status) byte */
  sxBuf[n++] = *srcPtr++;
  /* copy bytes until either the end of sysex is reached
     or there is no more data in the input buffer */
  while(n < count)
    if( *srcPtr & 0x80) break; /* end of sysex */
    else sxBuf[n++] = *srcPtr++;
  port->sysExLength = n;
  if(port->sysExLength >= MAX_SYSEX_BUFFER) 
    { /* fail if not enough sysex space */
      success(false);
      return -1;
    }
  if( (n >= count) || (srcPtr[n] & 0x80) != 0x80)
    port->flags |= PENDING_SYSEX; /* not enough data buffered */
  else
    {
      /* copy the last (status) byte */
      if(*srcPtr == 0xF7) sxBuf[n++] = *srcPtr++;
      sendLongMidiData(port->handle, sxBuf, n);
      port->sysExLength = 0; /* data has been sent */
    }
  return n;
}


/*************************************************************************************
 finishSysExCommand: Finish a previously started SysEx message. This function is
                     only called if the PENDING_SYSEX flag has been set.
                     Return the number of bytes processed or -1 on error.
 *************************************************************************************/
int finishSysExCommand(sqMidiPort *port, char *bufferPtr, int count)
{ /* Still in a system exclusive message */
  unsigned char *buf = port->sysExBuffer;
  unsigned char *srcPtr = bufferPtr;

  /* copy unless status byte found */
  while(count && ((*srcPtr) & 0x80) == 0)
    if(port->sysExLength < MAX_SYSEX_BUFFER)
      {
        buf[port->sysExLength++] = *srcPtr++;
        count--;
      }
  /* Fail if we don't have enough space in the sysex buffer */
  if(port->sysExLength >= MAX_SYSEX_BUFFER)
    {
      port->flags &= ~PENDING_SYSEX;
      success(false);
      return -1;
    }
  /* return if the sysex message has not been finished */
  if(!count) return (usqIntptr_t) srcPtr - (usqIntptr_t)bufferPtr;
  /* copy the last (status) byte */
  if(*srcPtr == 0xF7) buf[port->sysExLength++] = *srcPtr++;
  sendLongMidiData(port->handle, buf, port->sysExLength);
  port->sysExLength = 0; /* data has been sent */
  return (usqIntptr_t) srcPtr - (usqIntptr_t)bufferPtr;
}

/***************************************************************
 Helpers
 ***************************************************************/

/* Return the port with the given number or NULL */
static sqMidiPort* GetPort(int portNum)
{
  if(portNum > MAX_DEVICES || portNum < 0)
    {
      success(false);
      return NULL;
    }
  else
    return midiPorts[portNum];
}

/* Free an allocated port */
static void FreePort(int portNum)
{ sqMidiPort *port = GetPort(portNum);

  if(!port) return;
  /* output cleanup */
  if(port->schedulerThread) TerminateThread(port->schedulerThread,0);
  if(port->outBufferData) CloseHandle(port->outBufferData);
  if(port->outBufferMutex) CloseHandle(port->outBufferMutex);
  if(port->outBuffer) free(port->outBuffer);
  if(port->sysExBuffer) free(port->sysExBuffer);
  /* input cleanup */
  if(port->inBuffer) free(port->inBuffer);
  /* generic cleanup */
  free(port);
  midiPorts[portNum] = NULL;
}


/* Allocate a new port and setup buffers for input or output */
static sqMidiPort *AllocatePort(int outFlag)
{ sqMidiPort *port;
  DWORD id;

  port = (sqMidiPort*)calloc(1,sizeof(sqMidiPort));
  if(!port) return NULL;
  if(outFlag)
    {
      port->outBuffer = (sqMidiOutEvent*)calloc(MAX_MIDI_BUFFER+1, sizeof(sqMidiOutEvent));
      port->sysExBuffer = (char*)calloc(1,MAX_SYSEX_BUFFER+1);
      port->outBufferData = CreateEvent(NULL, 0, 0, NULL);
      port->outBufferMutex = CreateMutex(NULL, 0, NULL);
      port->schedulerThread = 
        CreateThread(NULL,                    /* No security descriptor */
                     128*1024,                /* max stack size     */
                     (LPTHREAD_START_ROUTINE) &midiScheduler, /* what to do */
                     port,                    /* parameter for thread   */
                     CREATE_SUSPENDED | STACK_SIZE_PARAM_IS_A_RESERVATION,
                     &id);                    /* return value for thread id */
      if(!port->schedulerThread)
        printLastError(TEXT("CreateThread() failed"));
      if(!SetThreadPriority(port->schedulerThread, THREAD_PRIORITY_TIME_CRITICAL))
        printLastError(TEXT("SetThreadPriority() failed"));
      if(!ResumeThread(port->schedulerThread))
        printLastError(TEXT("ResumeThread() failed"));
    }
  else
    {
      port->inBuffer = (sqMidiInEvent*) calloc(MAX_MIDI_BUFFER+1, sizeof(sqMidiInEvent));
    }
  return port;
}

/***************************************************************************
 Exported functions
 ***************************************************************************/

/* Close the given MIDI port. Do nothing if the port is not open.
   Fail if there is no port of the given number.*/
int sqMIDIClosePort(int portNum)
{  sqMidiPort *port;

  port = GetPort(portNum);
  if(!port) return 0; /* already closed or invalid port number */
  if(port->flags & MIDI_OUT_DEVICE)
    { /* out port */
      midiOutReset((HMIDIOUT)port->handle);
      midiOutClose((HMIDIOUT)port->handle);
    }	
  else
    { /* in port */
      midiInStop((HMIDIIN)port->handle);
      midiInReset((HMIDIIN)port->handle);
      midiInClose((HMIDIIN)port->handle);
    }
  FreePort(portNum);
  return 1;
}

/* Return the current value of the clock used to schedule MIDI events.
   The MIDI clock is assumed to wrap at or before half the maximum
   positive SmallInteger value. This allows events to be scheduled
   into the future without overflowing into LargePositiveIntegers. 
   This implementation does not support event scheduling, so it
   just returns the value of the Squeak millisecond clock. */
int sqMIDIGetClock(void) {
	return timeGetTime() & 0x0FFFFFFF;
}

/* Return the number of available MIDI interfaces, including both
   hardware ports and software entities that act like ports. Ports
   are numbered from 0 to N-1, where N is the number returned by this
   primitive. */
int sqMIDIGetPortCount(void) {
	return midiInNumDevices + midiOutNumDevices;
}

/* Return an integer indicating the directionality of the given
   port where: 1 = input, 2 = output, 3 = bidirectional. Fail if
   there is no port of the given number. */
int sqMIDIGetPortDirectionality(int portNum) {
  if(portNum < 0 || portNum >= midiInNumDevices+midiOutNumDevices)
    return success(false);
  return portNum < midiOutNumDevices ? MIDI_OUT_DEVICE : MIDI_IN_DEVICE;
}

/* Copy the name of the given MIDI port into the string at the given
   address. Copy at most length characters, and return the number of
   characters copied. Fail if there is no port of the given number.*/
int sqMIDIGetPortName(int portNum, char * namePtr, int length) {
  TCHAR *portName;
	int count, i;
  MIDIOUTCAPS outCaps;
  MIDIINCAPS inCaps;

  if(portNum < 0 || portNum >= midiInNumDevices+midiOutNumDevices)
    return success(false);
  if(portNum < midiOutNumDevices)
    {
      midiOutGetDevCaps(portNum-1, &outCaps, sizeof(outCaps));
      portName = outCaps.szPname;
    }
  else
    {
      midiInGetDevCaps(portNum - midiOutNumDevices, &inCaps, sizeof(inCaps));
      portName = inCaps.szPname;
    }
	count = lstrlen(portName);
	if (count > length) count = length;
  for(i=0;i<count;i++)
    namePtr[i] = (char) portName[i];
	return count;
}

/* Open the given port, if possible. If non-zero, readSemaphoreIndex
   specifies the index in the external objects array of a semaphore
   to be signalled when incoming MIDI data is available. Note that
   not all implementations support read semaphores (this one does);
   see sqMIDICanUseSemaphore. The interfaceClockRate parameter
   specifies the clock speed for an external MIDI interface
   adaptor on platforms that use such adaptors (e.g., Macintosh)
   and is ignored with Win32.
   Fail if there is no port of the given number.*/
int sqMIDIOpenPort(int portNum, int readSemaIndex, int interfaceClockRate) {
  DWORD err;
  sqMidiPort *port = GetPort(portNum);

  if(port) return 1; /* already open */
  if(portNum >= midiInNumDevices+midiOutNumDevices)
    return success(false);
  if(portNum < midiOutNumDevices)
    { /* output port */
      MIDIOUTCAPS caps;
      HMIDIOUT handle;

      midiOutGetDevCaps(portNum-1, &caps, sizeof(caps));
      port = AllocatePort(1); /* Allocate the output port */
      if(!port) { success(false);  return 0;}
      port->flags = MIDI_OUT_DEVICE;
      midiPorts[portNum] = port;
      MoveMemory(port->name, caps.szPname, MAXPNAMELEN * sizeof(TCHAR));
      port->name[MAXPNAMELEN] = 0;
      DBGPRINTF(TEXT("Opening output interface %s\n"), caps.szPname);
      err = midiOutOpen(&handle, portNum-1, 0, 0, 0);
      if(err)
        { /* fail if we can't open a particular output device */
#ifndef NO_WARNINGS
          TCHAR errorText[256];
          midiOutGetErrorText(err,errorText,255);
          warnPrintf(TEXT("Failed to open MIDI output device %s:\n%s\n"),
                  caps.szPname, errorText);
#endif
          FreePort(portNum);
          success(false);
          return 0;
        }
      port->handle = handle;
    }
  else
    { /* input port */
      MIDIINCAPS caps;
      HMIDIIN handle;

      midiInGetDevCaps(portNum - midiOutNumDevices, &caps, sizeof(caps));
      port = AllocatePort(0); /* Allocate the input port */
      if(!port) { success(false);  return 0;}
      port->flags = MIDI_IN_DEVICE;
      port->semaphore = readSemaIndex;
      midiPorts[portNum] = port;
      MoveMemory(port->name, caps.szPname, MAXPNAMELEN * sizeof(TCHAR));
      port->name[MAXPNAMELEN] = 0;
      DBGPRINTF(TEXT("Opening input interface %s\n"), caps.szPname);
      err = midiInOpen(&handle, portNum - midiOutNumDevices,
                       (DWORD_PTR)midiInCallback, (DWORD_PTR)port, CALLBACK_FUNCTION);
      if(err)
        { /* fail if we can't open a particular input device */
#ifndef NO_WARNINGS
          TCHAR errorText[256];
          midiInGetErrorText(err,errorText,255);
          warnPrintf(TEXT("Failed to open MIDI input device %s:\n%s\n"),
                  caps.szPname, errorText);
#endif
          FreePort(portNum);
          success(false);
          return 0;
        }
      port->handle = handle;
      midiInStart(handle);
    }
  return 1;
}

/* Read or write the given MIDI driver parameter. If modify is 0,
   then newValue is ignored and the current value of the specified
   parameter is returned. If modify is non-zero, then the specified
   parameter is set to newValue. Note that many MIDI driver parameters
   are read-only; attempting to set one of these parameters fails.
   For boolean parameters, true = 1, false = 0. */
int sqMIDIParameter(int whichParameter, int modify, int newValue) {
  int i;
  sqMidiPort *port;

	if (modify == 0) {
		switch(whichParameter) {
		case sqMIDIInstalled:          return 1;
		case sqMIDIVersion:            return 100;
		case sqMIDIHasBuffer:          return 1;
		case sqMIDIHasDurs:            return 0;
		case sqMIDICanSetClock:        return 0;
		case sqMIDICanUseSemaphore:    return 1;
		case sqMIDIEchoOn:             return 0 /* isEchoEnabled */;
		case sqMIDIUseControllerCache: return isControllerCaching;
		case sqMIDIEventsAvailable:
      for(i=0;i<MAX_DEVICES;i++)
        if(midiPorts[i])
          if(midiPorts[i]->inBufferStart != midiPorts[i]->inBufferEnd)
		        return 1;
      return 0;
		case sqMIDIFlushDriver:        return 0;
		case sqMIDIClockTicksPerSec:   return 1000;
		case sqMIDIHasInputClock:      return 1;
		default:
			return success(false);
		}
	} else {
		switch(whichParameter) {
		case sqMIDIInstalled:
		case sqMIDIVersion:
		case sqMIDIHasBuffer:
		case sqMIDIHasDurs:
		case sqMIDICanSetClock:
		case sqMIDICanUseSemaphore:
			return success(false);
			break;
		case sqMIDIEchoOn:
      isEchoEnabled = newValue != 0;
			break;
		case sqMIDIUseControllerCache:
      isControllerCaching = newValue != 0;
			break;
		case sqMIDIEventsAvailable:
			return success(false);
			break;
		case sqMIDIFlushDriver:
      for(i=0;i<MAX_DEVICES;i++)
        {
          port = midiPorts[i];
          if(port) {
            if(port->flags & MIDI_OUT_DEVICE)
              {
                /* reset output device */
                WaitForSingleObject(port->outBufferMutex, INFINITE);
                port->nOutEvents = 0;
                ReleaseMutex(port->outBufferMutex);
                midiOutReset((HMIDIOUT) (midiPorts[i]->handle));
              }
            else
              {
                /* reset input device */
                midiInStop((HMIDIIN) (port->handle));
                midiInReset((HMIDIIN) (port->handle));
                midiInStart((HMIDIIN) (port->handle));
                port->inBufferStart = port->inBufferEnd = 0;
              }
		  }
        }
			break;
		case sqMIDIClockTicksPerSec:
			return success(false);
			break;
		default:
			return success(false);
		}
	}
	return 1;
}

int sqMIDIParameterSet(int whichParameter, int newValue)
{
	return sqMIDIParameter(whichParameter, 1, newValue);
}

int sqMIDIParameterGet(int whichParameter)
{
	return sqMIDIParameter(whichParameter, 0, 0);
}


/* bufferPtr is the address of the first byte of a Smalltalk
   ByteArray of the given length. Copy up to (length - 4) bytes
   of incoming MIDI data into that buffer, preceded by a 4-byte
   timestamp in the units of the MIDI clock, most significant byte
   first. Implementations that do not support timestamping of
   incoming data as it arrives (see sqMIDIHasInputClock) simply
   set the timestamp to the value of the MIDI clock when this
   function is called. Return the total number of bytes read,
   including the timestamp bytes. Return zero if no data is
   available. Fail if the buffer is shorter than five bytes,
   since there must be enough room for the timestamp plus at
   least one data byte. */
int sqMIDIPortReadInto(int portNum, int count, char * bufferPtr) {
	int bytesRead, stamped;
  DWORD index, i, data, len, stamp;
  unsigned char *dstPtr;
  sqMidiPort *port;

  /* require at least 1 byte for midi data */
	if (count < 5) return success(false);
  port = GetPort(portNum);
  if(!port) return success(false);

  if(port->inBufferStart == port->inBufferEnd)
		return 0; /* no data */

  /* get data */
  index = port->inBufferStart;
  stamped = 0; /* We don't have a time stamp yet */
  /* leave room for stamp */
  dstPtr = (char*)(bufferPtr+4);
  count -= 4;
  /* as long as there is data and space left */
  while( (port->pendingInputData || index != port->inBufferEnd) && count)
    {
      if(port->pendingInputData)
        {
          data = port->pendingInputData;
          stamp = port->pendingInputStamp;
        }
      else
        {
          data = port->inBuffer[index].data;
          stamp = port->inBuffer[index].stamp;
          /* adjust input */
          if(index == port->inBufferStart)
            port->inBufferStart++;
          index++;
          /* wrap around if necessary */
          if(index == MAX_MIDI_BUFFER)
            index = 0;
          if(port->inBufferStart == MAX_MIDI_BUFFER)
            port->inBufferStart = 0;
        }
      len = data >> 24;
      if(!stamped)
        {
          *(int*)bufferPtr = stamp;
          stamped = 1;
        }
      /* copy data */
      for(i=0;i<len && count;i++,count--)
        {
          *dstPtr++ = (unsigned char) (data & 0xFF);
          data = data >> 8;
        }
      if(i < len)
        {
          /* There was not enough space left in the buffer;
             Store data back but adjust the byte length.
             NOTE: data has already been shifted so the bytes are correct */
          data &= 0x00FFFFFF; /* eventually clear header bits */
          data += (len-i) << 24;
          port->pendingInputData = data;
          port->pendingInputStamp = stamp;
        }
    }
  /* compute the number of bytes actually transmitted */
  bytesRead = (usqIntptr_t)dstPtr - (usqIntptr_t)bufferPtr;
  /* return zero if only the stamp is in the buffer */
	return bytesRead == 4 ? 0 : bytesRead;
}


/* bufferPtr is the address of the first byte of a Smalltalk
   ByteArray of the given length. Send its contents to the given
   port when the MIDI clock reaches the given time. If time equals
   zero, then send the data immediately. Implementations that do
   not support a timestamped output queue, such as this one, always
   send the data immediately; see sqMIDIHasBuffer. */
int sqMIDIPortWriteFromAt(int portNum, int count, char * bufferPtr, int time) {
  unsigned char *srcPtr = (char*) bufferPtr;
  unsigned char cmd;
  sqMidiPort *port;
  DWORD timeStamp;
  int nBytes, cmdLen;

  /* fetch scheduling time first so it will be accurate */
  timeStamp = timeGetTime() + (DWORD) time;
  /* fetch port */
  port = GetPort(portNum);
  if(!port) return success(false);
  if(0 == (port->flags & MIDI_OUT_DEVICE))
    return success(false); /* read-only ports fail on write */

  /* Check if we're still in a MIDI SysEx message from last time */
  if(port->flags & PENDING_SYSEX)
    { /* Still in a system exclusive message */
      nBytes = finishSysExCommand(port, srcPtr, count);
      if(nBytes < 0) return 0; /* error */
      count -= nBytes;
      srcPtr += nBytes;
    }
  /* Check if we're still in a short message from last time */
  if(port->pendingSize)
    { /* Yes; finish up the last command */
      while(count && port->pendingSize)
        {
          port->pendingCommand[port->pendingLength++] = *srcPtr++;
          count--; port->pendingSize--;
        }
      if(!port->pendingSize)
        scheduleShortMessage(port, *(DWORD*)&(port->pendingCommand[0]), port->pendingStamp);
    }

  /* Process midi data */
  while(count)
    {
      cmd = *srcPtr;
      if(cmd >= 0xF0)
        { /* Meta or Sysex command */
          cmdLen = midiMetaEventLengths[cmd & 0x0F];
          if(cmdLen <= 0)
            { /* variable length; find next status byte */
              nBytes = startSysExCommand(port, srcPtr, count);
              if(nBytes < 0) return 0; /* error */
              count -= nBytes;
              srcPtr += nBytes;
              continue;
            }
        }
      else
        { /* Channel message */
          cmdLen = 1;
          if(cmd >= 0x80) cmdLen++; /* new command */
          /* else use running status */
          if( ((cmd & 0xF0) != 0xC0) && ((cmd & 0xF0) != 0xD0))
            cmdLen++; /* all but program change and channel pressure have two data bytes */
        }
      /* check if enough data is in the buffer */
      if(cmdLen > count && port->nOutEvents < MAX_MIDI_BUFFER)
        break;/* no */

      /* have enough data; send it */
      scheduleShortMessage(port, *(DWORD*)srcPtr, timeStamp);
      srcPtr += cmdLen;
      count -= cmdLen;
    }
  if(count && count < cmdLen)
    { /* if there is remaining data we have a short command left */
      *(DWORD*) &(port->pendingCommand[0]) = *(DWORD*)srcPtr;
      port->pendingStamp = timeStamp;
      port->pendingLength = count;
      port->pendingSize = cmdLen - count;
      srcPtr += count;
    }
	return (usqIntptr_t) srcPtr - (usqIntptr_t) bufferPtr;
}

/*************************************************************************************
 SetupMIDI: Setup any MIDI related stuff.
 *************************************************************************************/
int midiInit(void)
{ int i;
  int maxDevs = MAX_DEVICES / 2;
  DWORD id;

  /* reset MIDI handles */
  for(i=0;i<MAX_DEVICES;i++)
    {
      midiPorts[i] = NULL;
    }
  /* determine midi devices */
  midiInNumDevices = midiInGetNumDevs();
  midiOutNumDevices = midiOutGetNumDevs();
  /* If we have MIDI out devices, then we can use the mapper */
  if(midiOutNumDevices) midiOutNumDevices++;
  /* clamp to max devices (even though it's unlikely to exceed it) */
  if(midiOutNumDevices > maxDevs) midiOutNumDevices = maxDevs;
  if(midiInNumDevices > maxDevs) midiInNumDevices = maxDevs;

  /* Create the input event and associated notification thread */
  midiInputEvent = CreateEvent(NULL, 1, 0, NULL);
  midiInputThread =
        CreateThread(NULL,                    /* No security descriptor */
                     128*1024,                /* max stack size     */
                     (LPTHREAD_START_ROUTINE) &midiNotifyThread, /* what to do */
                     NULL,                    /* parameter for thread   */
                     STACK_SIZE_PARAM_IS_A_RESERVATION,  /* create running */
                     &id);                    /* return value for thread id */
  return midiInputEvent && midiInputThread;
}

int midiShutdown(void)
{
	int i;
	/* Close all open ports */
	for(i=0; i<MAX_DEVICES; i++) sqMIDIClosePort(i);
	TerminateThread(midiInputThread, 0);
	CloseHandle(midiInputEvent);
	midiInputThread = NULL;
	midiInputEvent = NULL;
	return 1;
}


#endif /* NO_MIDI */
