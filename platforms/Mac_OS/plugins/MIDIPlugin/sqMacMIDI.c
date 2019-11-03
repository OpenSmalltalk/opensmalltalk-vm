#include "sq.h"
#include "MIDIPlugin.h"
#include <Carbon/Carbon.h>
#include <QuickTime/QuickTimeMusic.h>

extern struct VirtualMachine *interpreterProxy;

/* Quicktime MIDI note allocator and channels */
#define FIRST_DRUM_KIT 16385

void* portNamesFn;
void* portIsOpenFn;
void* portSetControlFn;
void* serialPortOpenFn;
void* serialPortCloseFn;
void* serialPortCountFn;
void* serialPortReadIntoFn;
void* serialPortWriteFromFn;

NoteAllocator na = nil;
NoteChannel channel[16] = {
	nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil};

/* Initial instruments: drums on channel 10, piano on all other channels */
int channelInstrument[16] = {
	1, 1, 1, 1, 1, 1, 1, 1, 1, FIRST_DRUM_KIT, 1, 1, 1, 1, 1, 1};

/* Quicktime MIDI parser state */
enum {idle, want1of2, want2of2, want1of1, sysExclusive};
int state = idle;
int argByte1 = 0;
int argByte2 = 0;
int lastCmdByte = nil;

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


/*** Private Functions ***/
int setMidiClockRate(int portNum, int interfaceClockRate);
int sqMIDIGetSerialPortCount(void);

/*** Quicktime MIDI Support Functions ***/
void closeQuicktimeMIDIPort(void);
void openQuicktimeMIDIPort(void);
void performMIDICmd(int cmdByte, int arg1, int arg2);
void processMIDIByte(int aByte);
void startMIDICommand(int cmdByte);

/* initialize/shutdown */
int midiInit() { 
	portIsOpenFn = interpreterProxy->ioLoadFunctionFrom("serialPortIsOpen", "SerialPlugin");
    if (portIsOpenFn == 0) {
    	portIsOpenFn = interpreterProxy->ioLoadFunctionFrom("serialPortIsOpen", "");
		   if (portIsOpenFn == 0)
		    return interpreterProxy->success(false);
	}

	portSetControlFn = interpreterProxy->ioLoadFunctionFrom("serialPortSetControl", "SerialPlugin");
    if (portSetControlFn == 0) {
    	portSetControlFn = interpreterProxy->ioLoadFunctionFrom("serialPortSetControl", "");
		if (portSetControlFn == 0)
		    return interpreterProxy->success(false);
	}

	serialPortCloseFn = interpreterProxy->ioLoadFunctionFrom("serialPortClose", "SerialPlugin");
    if (serialPortCloseFn == 0) {
    	serialPortCloseFn = interpreterProxy->ioLoadFunctionFrom("serialPortClose", "");
		if (serialPortCloseFn == 0)
		    return interpreterProxy->success(false);
	}

	serialPortCountFn = interpreterProxy->ioLoadFunctionFrom("serialPortCount", "SerialPlugin");
    if (serialPortCountFn == 0) {
	    serialPortCountFn = interpreterProxy->ioLoadFunctionFrom("serialPortCount", "");
	    if (serialPortCountFn == 0)
	    	return interpreterProxy->success(false);
	}

	portNamesFn = interpreterProxy->ioLoadFunctionFrom("serialPortNames", "SerialPlugin");
    if (portNamesFn == 0) {
    	portNamesFn = interpreterProxy->ioLoadFunctionFrom("serialPortNames", "");
        if (portNamesFn == 0) 
		    return interpreterProxy->success(false);
	}

	serialPortOpenFn = interpreterProxy->ioLoadFunctionFrom("serialPortOpen", "SerialPlugin");
    if (serialPortOpenFn == 0) {
	    serialPortOpenFn = interpreterProxy->ioLoadFunctionFrom("serialPortOpen", "");
        if (serialPortOpenFn == 0)
 		    return interpreterProxy->success(false);
	}

	serialPortReadIntoFn = interpreterProxy->ioLoadFunctionFrom("serialPortReadInto", "SerialPlugin");
    if (serialPortReadIntoFn == 0) {
    	serialPortReadIntoFn = interpreterProxy->ioLoadFunctionFrom("serialPortReadInto", "");
        if (serialPortReadIntoFn == 0)
            return interpreterProxy->success(false);
	}

	serialPortWriteFromFn = interpreterProxy->ioLoadFunctionFrom("serialPortWriteFrom", "SerialPlugin");
    if (serialPortWriteFromFn == 0) {
    	serialPortWriteFromFn = interpreterProxy->ioLoadFunctionFrom("serialPortWriteFrom", "");
        if (serialPortWriteFromFn == 0)
            return interpreterProxy->success(false);
	}

    return true; 
}

int midiShutdown() {
	return 1;
}

/* helper function for MIDI module */
int sqMIDIParameter(int whichParameter, int modify, int newValue);

int sqMIDIParameterSet(int whichParameter, int newValue) {
	sqMIDIParameter(whichParameter, true, newValue);
	return 0;
}

int sqMIDIParameterGet(int whichParameter) {
	sqMIDIParameter(whichParameter, false, 0);
	return 0;
}

int setMidiClockRate(int portNum, int interfaceClockRate) {
#pragma unused(portNum, interfaceClockRate)
/* Put the given port into MIDI mode, which uses a clock supplied
   by an external MIDI interface adaptor to determine the baud rate.
   Possible external clock rates: 31.25 KHz, 0.5 MHz, 1 MHz, or 2 MHz. */
    return false;
}/*** MIDI Parameters (used with sqMIDIParameter function) ***/

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
/* Read-only. Return 1 if this MIDI driverÕs clock can be set
   via an extended primitive, 0 if not. */

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

/*** MIDI Functions ***/

int sqMIDIClosePort(int portNum) {
/* Close the given MIDI port. Do nothing if the port is not open.
   Fail if there is no port of the given number.*/

	int serialPorts;

	serialPorts = sqMIDIGetSerialPortCount();
	if (portNum == serialPorts) {
		closeQuicktimeMIDIPort();
		return 0;
	} else {

    	if (serialPortCloseFn == 0) {
			return interpreterProxy->success(false);
		}

		return ((int (*) (int)) serialPortCloseFn)(portNum);
	}
}

int sqMIDIGetClock(void) {
/* Return the current value of the clock used to schedule MIDI events.
   The MIDI clock is assumed to wrap at or before half the maximum
   positive SmallInteger value. This allows events to be scheduled
   into the future without overflowing into LargePositiveIntegers. 
   This implementation does not support event scheduling, so it
   just returns the value of the Squeak millisecond clock. */

	return interpreterProxy->ioMicroMSecs();
}

int sqMIDIGetSerialPortCount(void) {
/* Return the number of available 
   hardware ports and software entities that act like ports. Ports
   are numbered from 0 to N-1, where N is the number returned by this
   primitive. */

    int serialPorts;

    if (serialPortCountFn == 0) {
		return 0;
	}

	serialPorts = ((int (*) (void)) serialPortCountFn)();
	return serialPorts;  /* serial ports */
}

int sqMIDIGetPortCount(void) {
/* Return the number of available MIDI interfaces, including both
   hardware ports and software entities that act like ports. Ports
   are numbered from 0 to N-1, where N is the number returned by this
   primitive. */

	return sqMIDIGetSerialPortCount() + 1;  /* serial ports + QuickTime Synth */
}

int sqMIDIGetPortDirectionality(int portNum) {
/* Return an integer indicating the directionality of the given
   port where: 1 = input, 2 = output, 3 = bidirectional. Fail if
   there is no port of the given number. */

	
	int serialPorts;
	
	serialPorts = sqMIDIGetSerialPortCount();
	if (portNum > serialPorts) return interpreterProxy->success(false);
	if (portNum == serialPorts) {
		return 2;
	} else {
		return 3;
	}
}

int sqMIDIGetPortName(int portNum, char * namePtr, int length) {
/* Copy the name of the given MIDI port into the string at the given
   address. Copy at most length characters, and return the number of
   characters copied. Fail if there is no port of the given number.*/

	char userName[256], inName[256], outName[256];
	int serialPorts, count;
	
	serialPorts = sqMIDIGetSerialPortCount();
	if (portNum > serialPorts) return interpreterProxy->success(false);

	if (portNum == serialPorts) {
		strcpy(userName, "QuickTime MIDI");
	} else {
 
    	if (portNamesFn == 0) {
			return 0;
		}

		((int (*) (int , char *, char *, char *)) portNamesFn)(portNum, userName, inName, outName);
	}

	count = strlen(userName);
	if (count > length) count = length;
	memcpy((void *) namePtr, userName, count);
	return count;
}

int sqMIDIOpenPort(int portNum, int readSemaIndex, int interfaceClockRate) {
/* Open the given port, if possible. If non-zero, readSemaphoreIndex
   specifies the index in the external objects array of a semaphore
   to be signalled when incoming MIDI data is available. Note that
   not all implementations support read semaphores (this one does
   not); see sqMIDICanUseSemaphore. The interfaceClockRate parameter
   specifies the clock speed for an external MIDI interface
   adaptor on platforms that use such adaptors (e.g., Macintosh).
   Fail if there is no port of the given number.*/

#pragma unused(readSemaIndex)
	int serialPorts;
	int err;


	serialPorts = sqMIDIGetSerialPortCount();
	if (portNum > serialPorts) return interpreterProxy->success(false);

	if (portNum == serialPorts) {
		openQuicktimeMIDIPort();
		return 0;
	}

    if (serialPortOpenFn == 0) {
		return interpreterProxy->success(false);
	}

	err = ((int (*) (int , int , int , int , int , int , int , int , int ))serialPortOpenFn)(portNum, 9600, 1, 0, 8, 0, 0, 0, 0);
	if (!err) {
		err = setMidiClockRate(portNum, interfaceClockRate);
		if (err) {
			sqMIDIClosePort(portNum);
		}
	}   
	return 0;
}

int sqMIDIParameter(int whichParameter, int modify, int newValue) {
/* Read or write the given MIDI driver parameter. If modify is 0,
   then newValue is ignored and the current value of the specified
   parameter is returned. If modify is non-zero, then the specified
   parameter is set to newValue. Note that many MIDI driver parameters
   are read-only; attempting to set one of these parameters fails.
   For boolean parameters, true = 1, false = 0. */
#pragma unused(newValue)

	if (modify == 0) {
		switch(whichParameter) {
		case sqMIDIInstalled:
			return 1;
			break;
		case sqMIDIVersion:
			return 100;
			break;
		case sqMIDIHasBuffer:
		case sqMIDIHasDurs:
		case sqMIDICanSetClock:
		case sqMIDICanUseSemaphore:
		case sqMIDIEchoOn:
		case sqMIDIUseControllerCache:
			return 0;
			break;
		case sqMIDIEventsAvailable:
			return 1;  /* pretend that events are always available */
			break;
		case sqMIDIFlushDriver:
			return 0;
			break;
		case sqMIDIClockTicksPerSec:
			return 1000;
			break;
		case sqMIDIHasInputClock:
			return 0;
			break;
		default:
			return interpreterProxy->success(false);
		}
	} else {
		switch(whichParameter) {
		case sqMIDIInstalled:
		case sqMIDIVersion:
		case sqMIDIHasBuffer:
		case sqMIDIHasDurs:
		case sqMIDICanSetClock:
		case sqMIDICanUseSemaphore:
			return interpreterProxy->success(false);
			break;
		case sqMIDIEchoOn:
			/* noop; echoing not supported */
			break;
		case sqMIDIUseControllerCache:
			/* noop; controller cache not supported */
			break;
		case sqMIDIEventsAvailable:
			return interpreterProxy->success(false);
			break;
		case sqMIDIFlushDriver:
			/* noop; buffer flushing not supported */
			break;
		case sqMIDIClockTicksPerSec:
			return interpreterProxy->success(false);
			break;
		default:
			return interpreterProxy->success(false);
		}
	}
	return 0;
}

int sqMIDIPortReadInto(int portNum, int count, char * bufferPtr) {
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

	int bytesRead;

	if (count < 5) return interpreterProxy->success(false);

    if (serialPortReadIntoFn == 0) {
		return interpreterProxy->success(false);
	}

	bytesRead = ((int (*) (int , int , int )) serialPortReadIntoFn)(portNum, count - 4, bufferPtr + 4);

	if (bytesRead == 0) return 0;
	*((int *) bufferPtr) = sqMIDIGetClock();  /* set timestamp */
	return bytesRead + 4;
}

int sqMIDIPortWriteFromAt(int portNum, int count, char *bufferPtr, int time) {
/* bufferPtr is the address of the first byte of a Smalltalk
   ByteArray of the given length. Send its contents to the given
   port when the MIDI clock reaches the given time. If time equals
   zero, then send the data immediately. Implementations that do
   not support a timestamped output queue, such as this one, always
   send the data immediately; see sqMIDIHasBuffer. */
#pragma unused(time)
	int serialPorts, i;
	unsigned char *bytePtr;
	
	serialPorts = sqMIDIGetSerialPortCount();
	if (portNum > serialPorts) return interpreterProxy->success(false);

	if (portNum == serialPorts) {
		if (!na) return interpreterProxy->success(false);  /* QuickTime port not open */
		bytePtr = (unsigned char *) bufferPtr;
		for (i = 0; i < count; i++) {
			processMIDIByte(*bytePtr++);
		}
		return count;
	}

    if (serialPortWriteFromFn == 0) {
		return interpreterProxy->success(false);
	}

	return ((int (*) (int , int , int )) serialPortWriteFromFn)(portNum, count - 4, bufferPtr + 4);
}

/*** Quicktime MIDI Support Functions ***/

void closeQuicktimeMIDIPort(void) {
	int i;

	if (!na) return;
	for (i = 0; i < 16; i++) {
		/* dispose of note channels */
		if (channel[i]) NADisposeNoteChannel(na, channel[i]);
		channel[i] = nil;
	}
	CloseComponent(na);  /* close note allocator */
}

void openQuicktimeMIDIPort(void) {
	ComponentResult err;
	NoteRequest nr;
	NoteChannel nc;
	int i;
	short shortpoly;
	Fixed fixedtypical;
	
	closeQuicktimeMIDIPort();
	na = OpenDefaultComponent('nota', 0);
	if (!na) return;

	for (i = 0; i < 16; i++) {
		shortpoly = CFSwapInt16HostToBig(11);
		memcpy(&nr.info.polyphony,&shortpoly,2);			/* max simultaneous tones */
		fixedtypical = CFSwapInt32HostToBig(0x00010000);
		memcpy(&nr.info.typicalPolyphony,&fixedtypical,4);

		NAStuffToneDescription(na, 1, &nr.tone);
		err = NANewNoteChannel(na, &nr, &nc);
		if (err || !nc) {
			closeQuicktimeMIDIPort();
			return;
		}
		NAResetNoteChannel(na, nc);
		NASetInstrumentNumber(na, nc, channelInstrument[i]);
		channel[i] = nc;
	}
	state = idle;
	argByte1 = 0;
	argByte2 = 0;
	lastCmdByte = nil;
	return;
}

void performMIDICmd(int cmdByte, int arg1, int arg2) {
	/* Perform the given MIDI command with the given arguments. */

	int ch, cmd, val, instrument, bend;

	ch = cmdByte & 0x0F;
	cmd = cmdByte & 0xF0;
	if (cmd == 128) {  /* note off */
		NAPlayNote(na, channel[ch], arg1, 0);
	}
	if (cmd == 144) {  /* note on */
		NAPlayNote(na, channel[ch], arg1, arg2);
	}
	if (cmd == 176) {  /* control change */
		if ((arg1 >= 32) && (arg1 <= 63)) {
			val = arg2 << 1;  /* LSB of controllers 0-31 */
		} else {
			val = arg2 << 8;  /* scale MSB to QT controller range */
		}
		NASetController(na, channel[ch], arg1, val);
	}
	if (cmd == 192) {  /* program change */
		if (ch == 9) {
			instrument = FIRST_DRUM_KIT + arg1;  /* if channel 10, select a drum set */
		} else {
			instrument = arg1 + 1;
		}
		NASetInstrumentNumber(na, channel[ch], instrument);
		channelInstrument[ch] = instrument;
	}
	if (cmd == 224) {  /* pitch bend */
		bend = ((arg2 << 7) + arg1) - (64 << 7);
		bend = bend / 32;  /* default sensitivity = +/- 2 semitones */
		NASetController(na, channel[ch], kControllerPitchBend, bend);
	}
}

void processMIDIByte(int aByte) {
	/* Process the given incoming MIDI byte and perform any completed commands. */

	if (aByte > 247) return;  /* skip all real-time messages */

	switch (state) {
	case idle:
		if (aByte >= 128) {
			/* start a new command using the action table */
			startMIDICommand(aByte);
		} else {
			/* data byte arrived in idle state: use running status if possible */
			if (lastCmdByte == 0) {
				return;  /* last command byte is not defined; just skip this byte */
			} else {
				/* process this data as if it had the last command byte in front of it */
				startMIDICommand(lastCmdByte);
				/* the previous line put us into a new state; we now do a recursive
			   	   call to process the data byte in this new state. */
				processMIDIByte(aByte);
				return;
			}
		}
		break;
	case want1of2:
		argByte1 = aByte;
		state = want2of2;
		break;
	case want2of2:
		argByte2 = aByte;
		performMIDICmd(lastCmdByte, argByte1, argByte2);
		state = idle;
		break;
	case want1of1:
		argByte1 = aByte;
		performMIDICmd(lastCmdByte, argByte1, 0);
		state = idle;
		break;
	case sysExclusive:
		if (aByte < 128) {
			/* skip a system exclusive data byte */
		} else {
			if (aByte < 248) {
				/* a system exclusive message can be terminated by any non-real-time command byte */
				state = idle;
				if (aByte != 247) {
					processMIDIByte(aByte);	/* if not endSysExclusive, byte is the start the next command */
				}
			}
		}
		break;
	}
}

void startMIDICommand(int cmdByte) {
	/* Start processing a MIDI message beginning with the given command byte. */

	int argCount;

	argCount = argumentBytes[cmdByte - 128];
	switch (argCount) {
	case 0:						/* start a zero argument command (e.g., a real-time message) */
		/* Stay in the current state and don't change active status.
		   Real-time messages may arrive between data bytes without disruption. */
		performMIDICmd(cmdByte, 0, 0);
		break;
	case 1:						/* start a one argument command */
		lastCmdByte = cmdByte;
		state = want1of1;
		break;
	case 2:						/* start a two argument command */
		lastCmdByte = cmdByte;
		state = want1of2;
		break;
	case 3:						/* start a variable length 'system exclusive' command */
		/* a system exclusive command clears running status */
		lastCmdByte = nil;
		state = sysExclusive;
		break;
	}
}
