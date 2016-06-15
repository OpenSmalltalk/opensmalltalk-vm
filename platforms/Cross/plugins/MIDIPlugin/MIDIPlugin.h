/* MIDI primitives */

/* module initialization/shutdown */
int midiInit(void);
int midiShutdown(void);

int sqMIDIGetClock(void);
int sqMIDIGetPortCount(void);
int sqMIDIGetPortDirectionality(int portNum);
int sqMIDIGetPortName(int portNum, char *namePtr, int length);
int sqMIDIClosePort(int portNum);
int sqMIDIOpenPort(int portNum, int readSemaIndex, int interfaceClockRate);
int sqMIDIParameterSet(int whichParameter, int newValue);
int sqMIDIParameterGet(int whichParameter);
int sqMIDIPortReadInto(int portNum, int count, char * bufferPtr);
int sqMIDIPortWriteFromAt(int portNum, int count, char * bufferPtr, int time);
