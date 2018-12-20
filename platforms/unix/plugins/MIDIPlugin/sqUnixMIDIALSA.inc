/* sqUnixMIDIALSA.c -- Unix MIDI support via ALSA
 * 
 *   Copyright (C) 1996-2007 by Florian Hars and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Florian@Hars.de
 * 
 * Reformatted for and integrated into Squeak build by: ian at
 * squeakland dot oh are gee
 * 
 * Modified for Scratch on Raspberry Pi by Manabu Sugiura
 * - Compatibility of MIDI instruments on Raspbian
 * - YAMAHA NSX-1 and NSX-39
 *   http://yamaha-webmusic.github.io/nsx1-apps/specs/ANMW820A-001-10-j.pdf
 *
 * Last edited: 2014-09-17 22:33:32 by manabu on raspberrypi
 */

/*** MIDI Parameters (used with sqMIDIParameter function) ***/

/* TODO: Why is this not in Cross/plugins/MIDIPlugin/MIDIPlugin.h ??? */

#define sqMIDIInstalled				 1
/* Read-only.  Return 1 if a MIDI driver is installed, 0 if not.  On
   OMS-based MIDI drivers, this returns 1 only if the OMS system is
   properly installed and configured. */

#define sqMIDIVersion				 2
/* Read-only.  Return the integer version number of this MIDI driver.
   The version numbering sequence is relative to a particular driver.
   That is, version 3 of the Macintosh MIDI driver is not necessarily
   related to version 3 of the Win95 MIDI driver. */

#define sqMIDIHasBuffer				 3
/* Read-only.  Return 1 if this MIDI driver has a time-stamped output
   buffer, 0 otherwise.  Such a buffer allows the client to schedule
   MIDI output packets to be sent later.  This can allow more precise
   timing, since the driver uses timer interrupts to send the data at
   the right time even if the processor is in the midst of a
   long-running Squeak primitive or is running some other application
   or system task. */

#define sqMIDIHasDurs				 4
/* Read-only.  Return 1 if this MIDI driver supports an extended
   primitive for note-playing that includes the note duration and
   schedules both the note-on and the note-off messages in the driver.
   Otherwise, return 0. */

#define sqMIDICanSetClock			 5
/* Read-only.  Return 1 if this MIDI driver's clock can be set via an
   extended primitive, 0 if not. */

#define sqMIDICanUseSemaphore			 6
/* Read-only.  Return 1 if this MIDI driver can signal a semaphore
   when MIDI input arrives.  Otherwise, return 0.  If this driver
   supports controller caching and it is enabled, then incoming
   controller messages will not signal the semaphore. */

#define sqMIDIEchoOn				 7
/* Read-write.  If this flag is set to a non-zero value, and if the
   driver supports echoing, then incoming MIDI events will be echoed
   immediately.  If this driver does not support echoing, then queries
   of this parameter will always return 0 and attempts to change its
   value will do nothing. */

#define sqMIDIUseControllerCache		 8
/* Read-write.  If this flag is set to a non-zero value, and if the
   driver supports a controller cache, then the driver will maintain a
   cache of the latest value seen for each MIDI controller, and
   control update messages will be filtered out of the incoming MIDI
   stream.  An extended MIDI primitive allows the client to poll the
   driver for the current value of each controller.  If this driver
   does not support a controller cache, then queries of this parameter
   will always return 0 and attempts to change its value will do
   nothing. */

#define sqMIDIEventsAvailable			 9
/* Read-only.  Return the number of MIDI packets in the input queue. */

#define sqMIDIFlushDriver			10
/* Write-only.  Setting this parameter to any value forces the driver
   to flush its I/0 buffer, discarding all unprocessed data.  Reading
   this parameter returns 0.  Setting this parameter will do nothing
   if the driver does not support buffer flushing. */

#define sqMIDIClockTicksPerSec			11
/* Read-only.  Return the MIDI clock rate in ticks per second. */

#define sqMIDIHasInputClock			12
/* Read-only.  Return 1 if this MIDI driver timestamps incoming MIDI
   data with the current value of the MIDI clock, 0 otherwise.  If the
   driver does not support such timestamping, then the client must
   read input data frequently and provide its own timestamping. */

/* Put the given port into MIDI mode, which uses a clock supplied by
   an external MIDI interface adaptor to determine the data rate.
   Possible external clock rates: 31.25 KHz, 0.5 MHz, 1 MHz, or 2
   MHz. */

#include <alsa/asoundlib.h>

static snd_seq_t *seq      =  0;
static int	  queue    =  0;
static int	  in_port  = -1;
static int	  out_port = -1;

/* MIDI Parser */

enum {idle, want1of2, want2of2, want1of1, sysExclusive};

static int state	= idle;
static int argByte1	= 0;
static int argByte2	= 0;
static int lastCmdByte	= 0;

/* number of argument bytes for each MIDI command */

char argumentBytes[128] = {
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
  3, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

/* Phonetic Symbols Buffer for YAMAHA NSX-1 */ 
char ps[128];
int ps_index = 0;

/* Port information Buffers 

Sample:
-MIDI settings
% acconet -o
Port  Client name   Port name
14:0  Midi Through  Midi Through Port-0
20:0  NSX-39        NSX-39 MIDI 1
128:0 TiMidity      TiMidity port 0
128:1 TiMidity      TiMidity port 1
128:2 TiMidity      TiMidity port 2
128:3 TiMidity      TiMidity port 3

-Port information Buffers
portIds[14,20,128,128,128,128]
portNums[0,0,0,1,2,3] 
*/

#define MAX_PORT_COUNT 256
int portIds[MAX_PORT_COUNT]; // client ids
int portNums[MAX_PORT_COUNT]; // port numbers
int portTypes[MAX_PORT_COUNT] = {0}; // now ignore input client

static void performMIDICmd(snd_seq_event_t *ev, int cmdByte, int arg1, int arg2);
static void processMIDIByte(snd_seq_event_t *ev, int aByte);
static void startMIDICommand(snd_seq_event_t *ev, int cmdByte);

extern struct VirtualMachine *interpreterProxy;


/* Close the given MIDI port.  Do nothing if the port is not open.
   Fail if there is no port of the given number.
*/
int sqMIDIClosePort(int portNum)
{
  int ret = 0;
  snd_seq_event_t ev;

  if(portTypes[portNum] == 0){
    if (out_port >= 0) {
      char all_note_off[] = {MIDI_CMD_CONTROL, 0x7b, 0x00};
      snd_seq_ev_set_sysex(&ev, sizeof(all_note_off), all_note_off);
      snd_seq_ev_set_direct(&ev);
      snd_seq_ev_set_source(&ev, 0);
      snd_seq_ev_set_dest(&ev, portIds[portNum], 0);
      snd_seq_event_output(seq, &ev);
      snd_seq_drain_output(seq);
      ret = snd_seq_delete_simple_port(seq, out_port);
      out_port= -1;
    }
  } else if (portTypes[portNum] == 1) {
    if (in_port >= 0) {
	ret= snd_seq_delete_simple_port(seq, in_port);
      in_port= -1;
    }
  } else {
    return interpreterProxy->success(false);
  } 
  return ret;
}

/* Return the current value of the clock used to schedule MIDI events.
   The MIDI clock is assumed to wrap at or before half the maximum
   positive SmallInteger value.  This allows events to be scheduled
   into the future without overflowing into LargePositiveIntegers.  
   This implementation does not support event scheduling, so it
   just returns the value of the Squeak millisecond clock.
*/
int sqMIDIGetClock(void)
{
  DPRINTF("sqMIDIGetClock\n");
  success(false);
  return 0;
}

/* Return the number of available MIDI interfaces, including both
   hardware ports and software entities that act like ports.  Ports
   are numbered from 0 to N-1, where N is the number returned by this
   primitive.
*/
int sqMIDIGetPortCount(void)
{
  DPRINTF("sqMIDIGetPortCount\n");
  snd_seq_client_info_t *cinfo;
  snd_seq_port_info_t *pinfo;
  
  snd_seq_client_info_alloca(&cinfo);
  snd_seq_client_info_set_client(cinfo, -1);
  
  int cap;
  int count = 0;
  int client;
  
  while (snd_seq_query_next_client(seq, cinfo) >= 0 ){
    client = snd_seq_client_info_get_client(cinfo);

    snd_seq_port_info_alloca(&pinfo);
    snd_seq_port_info_set_client(pinfo, client);
    snd_seq_port_info_set_port(pinfo, -1);
    
    // while the next port is available
    while (snd_seq_query_next_port(seq, pinfo) >= 0) {
      cap = snd_seq_port_info_get_capability(pinfo);
      // select output ports
      if ((cap & SND_SEQ_PORT_CAP_SUBS_WRITE) != 0 && snd_seq_client_id(seq) != snd_seq_port_info_get_client(pinfo)) {
	if (snd_seq_client_id(seq) != snd_seq_port_info_get_client(pinfo)) { 
	  if (count < MAX_PORT_COUNT && strcmp(snd_seq_client_info_get_name(cinfo), "Midi Through") != 0) { //skip Midi Through port
	    portIds[count] = snd_seq_port_info_get_client(pinfo);
	    portNums[count] = snd_seq_port_info_get_port(pinfo);
	    count++;
	  }
	}
      }
    }
  }
  success(true);
  return count; 
}

/* Return an integer indicating the directionality of the given
   port where: 1 = input, 2 = output, 3 = bidirectional.  Fail if
   there is no port of the given number.
*/
int sqMIDIGetPortDirectionality(int portNum)
{
  switch(portTypes[portNum])
    {
    case 0:	return 2;
    case 1:	return 1; //TODO: modify
    default:    return 0;
    }
  return interpreterProxy->success(false);
}

/* Copy the name of the given MIDI port into the string at the given
   address.  Copy at most length characters, and return the number of
   characters copied.  Fail if there is no port of the given number.
*/
int sqMIDIGetPortName(int portNum, char * namePtr, int length)
{
  int count;
  snd_seq_client_info_t *cinfo;
  char name[128];
  char portNumStr[128];

  snd_seq_client_info_alloca(&cinfo);
  snd_seq_client_info_set_client(cinfo, -1);
  snd_seq_get_any_client_info(seq, portIds[portNum], cinfo);
  sprintf(portNumStr, "%d", portNums[portNum]);
  sprintf(name, "%s <port:%s>", snd_seq_client_info_get_name(cinfo) , portNumStr);
  count = strlen(name);
  if (count > length) count= length;
  memcpy((void *)namePtr, name, count);
  
  success(true);
  return count;
}

/* Open the given port, if possible.  If non-zero, readSemaphoreIndex
   specifies the index in the external objects array of a semaphore to
   be signalled when incoming MIDI data is available.  Note that not
   all implementations support read semaphores (this one does not);
   see sqMIDICanUseSemaphore.  The interfaceClockRate parameter
   specifies the clock speed for an external MIDI interface adaptor on
   platforms that use such adaptors (e.g., Macintosh).  Fail if there
   is no port of the given number.
*/
int sqMIDIOpenPort(int portNum, int readSemaIndex, int interfaceClockRate)
{
  DPRINTF(("sqMIDIOpenPort(%d, %d, %d)\n", portNum, readSemaIndex, interfaceClockRate));
  out_port = -1;
  int type= SND_SEQ_PORT_TYPE_APPLICATION;
  switch (portTypes[portNum])
    {
    case 0:
      if (out_port < 0)
	{
	  int caps_out= SND_SEQ_PORT_CAP_READ|SND_SEQ_PORT_CAP_SUBS_READ;
	  out_port= snd_seq_create_simple_port(seq, "out", caps_out, type);
	  if (out_port < 0)
	    {
	      success(false);
	      return 0;
	    }
	  
	  if (snd_seq_connect_to(seq, out_port, portIds[portNum], 0) < 0)
            {
              success(false);
              return 0;
            }
	}
      break;

    case 1:
      if (in_port < 0)
	{
	  int caps_in= SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE;
	  in_port= snd_seq_create_simple_port(seq, "in", caps_in, type);
	  if (in_port < 0)
	    {
	      success(false);
	      return 0;
	    }
	}
      break;

    default:
      return interpreterProxy->success(false);
    }

  snd_seq_queue_tempo_t *tempo= 0;
  snd_seq_queue_tempo_alloca(&tempo);
  snd_seq_queue_tempo_set_tempo(tempo, interfaceClockRate);
  snd_seq_set_queue_tempo(seq, queue,  (snd_seq_queue_tempo_t*)tempo);

  success(true);
  return 0;
}

/* Read or write the given MIDI driver parameter.  If modify is 0,
   then newValue is ignored and the current value of the specified
   parameter is returned.  If modify is non-zero, then the specified
   parameter is set to newValue.  Note that many MIDI driver
   parameters are read-only; attempting to set one of these parameters
   fails.  For boolean parameters, true = 1, false = 0.
*/
int sqMIDIParameter(int whichParameter, int modify, int newValue)
{
  if (modify == 0)
    {
      switch (whichParameter)
	{
	case sqMIDIInstalled:
	  return 1;
	  break;

	case sqMIDIVersion:
	  return 100;
	  break;

	case sqMIDIHasBuffer:
	  return 1;
	  break;

	case sqMIDIHasDurs:
	case sqMIDICanSetClock:
	case sqMIDICanUseSemaphore:
	case sqMIDIEchoOn:
	case sqMIDIUseControllerCache:
	  return 0;
	  break;

	case sqMIDIEventsAvailable:
	  return 1;	/* pretend that events are always available */
	  break;

	case sqMIDIFlushDriver:
	  return 0;
	  break;

	case sqMIDIClockTicksPerSec:
	  {
	    snd_seq_queue_tempo_t *tempo= 0;
	    snd_seq_queue_tempo_alloca(&tempo);
	    snd_seq_get_queue_tempo(seq, queue, tempo);
	    return snd_seq_queue_tempo_get_tempo(tempo) / 1000.0;
	  }
	  break;

	case sqMIDIHasInputClock:
	  return 0;
	  break;

	default:
	  return interpreterProxy->success(false);
	}
    }
  else	/* modify != 0 */
    {
    switch (whichParameter)
      {
      case sqMIDIInstalled:
      case sqMIDIVersion:
      case sqMIDIHasBuffer:
      case sqMIDIHasDurs:
      case sqMIDICanSetClock:
      case sqMIDICanUseSemaphore:
	return interpreterProxy->success(false);
	break;

      case sqMIDIEchoOn:
	/* no-op; echoing not supported */
	break;

      case sqMIDIUseControllerCache:
	/* no-op; controller cache not supported */
	break;

      case sqMIDIEventsAvailable:
	return interpreterProxy->success(false);
	break;

      case sqMIDIFlushDriver:
	snd_seq_drain_output(seq);
	break;

      case sqMIDIClockTicksPerSec:
	{
	  snd_seq_queue_tempo_t *tempo= 0;
	  snd_seq_queue_tempo_alloca(&tempo);
	  snd_seq_queue_tempo_set_tempo(tempo, 1000.0 * newValue);
	  snd_seq_set_queue_tempo(seq, queue, (snd_seq_queue_tempo_t*)tempo);
	}
	break;

      default:
	return interpreterProxy->success(false);
      }
    }

  return 0;
}

/* bufferPtr is the address of the first byte of a Smalltalk ByteArray
   of the given length.  Copy up to (length - 4) bytes of incoming
   MIDI data into that buffer, preceded by a 4-byte timestamp in the
   units of the MIDI clock, most significant byte first.
   Implementations that do not support timestamping of incoming data
   as it arrives (see sqMIDIHasInputClock) simply set the timestamp to
   the value of the MIDI clock when this function is called.  Return
   the total number of bytes read, including the timestamp bytes.
   Return zero if no data is available.  Fail if the buffer is shorter
   than five bytes, since there must be enough room for the timestamp
   plus at least one data byte.
*/
int sqMIDIPortReadInto(int portNum, int count, char * bufferPtr)
{
  DPRINTF(("sqMIDIPortRead\n"));
  success(false);
  return 0;
}

/* bufferPtr is the address of the first byte of a Smalltalk ByteArray
   of the given length.  Send its contents to the given port when the
   MIDI clock reaches the given time.  If time equals zero, then send
   the data immediately.  Implementations that do not support a
   timestamped output queue, such as this one, always send the data
   immediately; see sqMIDIHasBuffer.
*/
int sqMIDIPortWriteFromAt(int portNum, int count, char * bufferPtr, int time)
{
  if (portTypes[portNum] == 0 || portTypes[portNum] == 1) {
      int i;
      snd_seq_event_t ev;
      unsigned char *bytePtr= (unsigned char *)bufferPtr;

      DPRINTF(("Port %d Write:", portNum));
      for (i= 0;  i < count;  ++i) DPRINTF((" %d", (int)bytePtr[i]));
      DPRINTF((" at %d\n", time));
      
      snd_seq_ev_clear(&ev);
      snd_seq_ev_set_source(&ev, out_port);
      snd_seq_ev_set_subs(&ev);
      snd_seq_ev_schedule_tick(&ev, queue, 0, time);
      for (i= 0;  i < count;  ++i)
    	processMIDIByte(&ev, *bytePtr++);
      snd_seq_event_output(seq, &ev);
      snd_seq_drain_output(seq);

      success(true);
      return count;
    }

  return interpreterProxy->success(false);
}


int midiInit(void)
{
  if (snd_seq_open(&seq, "default", SND_SEQ_OPEN_INPUT|SND_SEQ_OPEN_OUTPUT, 0) < 0) {
      success(false);
      return 0;
    }
  snd_seq_set_client_name(seq, "Squeak");
  queue= snd_seq_alloc_queue(seq);
  if (queue < 0)
    {
      snd_seq_close(seq);
      seq= NULL;
      success(false);
      return 0;
  }
  snd_seq_start_queue(seq, queue, NULL);

  success(true);
  return true;
}

int sqMIDIParameterSet(int whichParameter, int newValue)
{
  sqMIDIParameter(whichParameter, true, newValue);
  return 0;
}

int sqMIDIParameterGet(int whichParameter)
{
  sqMIDIParameter(whichParameter, false, 0);
  return 0;
}

int midiShutdown(void)
{
  DPRINTF(("midiShutdown\n"));
  success(false);
  return 0;
}

static void performMIDICmd(snd_seq_event_t *ev, int cmdByte, int arg1, int arg2)
{
  int cmd= cmdByte & 0xF0;
  int ch=  cmdByte & 0x0F;

  switch (cmd)
    {
    case 128:	/* note off */
      DPRINTF(("Note off %d, %d\n", ch, arg1));
      snd_seq_ev_set_noteoff(ev, ch, arg1, 0);
      break;

    case 144:	/* note on */
      DPRINTF(("Note on %d, %d, %d\n", ch, arg1, arg2));
      snd_seq_ev_set_noteon(ev, ch, arg1, arg2);
      break;

    case 176:	/* control change */
      {
	int val= ((arg1 >= 32) && (arg1 <= 63))
	  ? (arg2 << 1)		/* LSB of controllers 0-31 */
	  : (arg2 << 8);	/* scale MSB to QT controller range */
	snd_seq_ev_set_controller(ev, ch, arg1, val);
      }
      break;

    case 192:	/* program change */
      {
	int instrument= arg1 + 1;
	snd_seq_ev_set_pgmchange(ev, ch, instrument);
      }
      break;

    case 224:	/* pitch bend */
      {
	int bend= ((arg2 << 7) + arg1) - (64 << 7);
	bend /= 32;  /* default sensitivity = +/- 2 semitones */
	snd_seq_ev_set_pitchbend(ev, ch, bend);
      }
      break;
    }
}

static void processMIDIByte(snd_seq_event_t *ev, int aByte)
{
  int i;
  if (aByte > 247) return;	/* skip all real-time messages */

  switch (state)
    {
    case idle:
      if (aByte >= 128)		/* start a new command using the action table */
	startMIDICommand(ev, aByte);
      else	/* data byte arrived in idle state: use running status if possible */
	{
	  if (lastCmdByte == 0)	/* last command byte is not defined; just skip this byte */
	    return;
	  else
	    {
	      /* process this data as if it had the last command byte in front of it */
	      startMIDICommand(ev, lastCmdByte);
	      /* the previous line put us into a new state; we now do a recursive
		 call to process the data byte in this new state */
	      processMIDIByte(ev, aByte);
	      return;
	    }
	}
      break;

    case want1of2:
      argByte1= aByte;
      state= want2of2;
      break;

    case want2of2:
      argByte2= aByte;
      performMIDICmd(ev, lastCmdByte, argByte1, argByte2);
      state= idle;
      break;

    case want1of1:
      argByte1= aByte;
      performMIDICmd(ev, lastCmdByte, argByte1, 0);
      state= idle;
      break;

    case sysExclusive:
      if (aByte < 128)
	{
	  /* skip a system exclusive data byte */
       	  ps[ps_index] = aByte;
          ps_index++;
	}
      else
	{
	  if (aByte < 248)
	    {
	      /* a system exclusive message can be terminated by any non-real-time command byte */
	      state= idle;
	      if (aByte != 247)
		{
		  processMIDIByte(ev, aByte);	/* if not endSysExclusive, byte is the start the next command */
		}
              else{
		  ps[ps_index] = aByte;
                  ps_index++;
		  //ev->type = SND_SEQ_EVENT_SYSEX;
                  snd_seq_ev_set_sysex(ev, ps_index +1 , ps);
		  ps_index = 0;
	      }
	    }
	}
      break;
    }
}

static void startMIDICommand(snd_seq_event_t *ev, int cmdByte)
{
  int argCount= argumentBytes[cmdByte - 128];

  switch (argCount)
    {
    case 0:	/* start a zero argument command (e.g., a real-time message) */
      /* Stay in the current state and don't change active status.
	 Real-time messages may arrive between data bytes without disruption. */
      performMIDICmd(ev, cmdByte, 0, 0);
      break;

    case 1:	/* start a one argument command */
      lastCmdByte= cmdByte;
      state= want1of1;
      break;

    case 2:	/* start a two argument command */
      lastCmdByte= cmdByte;
      state= want1of2;
      break;

    case 3:	/* start a variable length 'system exclusive' command */
      /* a system exclusive command clears running status */
      lastCmdByte= 0;
      if(cmdByte == 240){
        ps[ps_index] = cmdByte;
	ps_index++;
      }
      state= sysExclusive;
      break;
    }
}
