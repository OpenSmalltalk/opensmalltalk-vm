/* sqUnixSoundMacOSX.c -- sound support for CoreAudio on Mac OS 10
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2008-04-21 14:53:42 by piumarta on emilia
 
  * Altered by johnmci@smalltalkconsulting.com to remove  static  defs, fix bugs, powerpc/intel support.
 
 
 *
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
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

// Notes:
// 
// The image always generates stereo samples.  Since the only
// supported hardware format is stereo, I cheerfully ignore the stereo
// flag in snd_Start().  (Mixing everything down to mono only to have
// the format converter break it back into stereo seems pointless.)


/// 
/// Things you can tweak, should you really want to...
/// 

// Do we obey the (huge) default "lead" time of 1024 frames (supplied
// by the image) when mixing frames into the buffer, or do we reduce
// the lead time to to an absolute (safe) minimum?
//
#define OBEY_LEAD_TIME	0

/// 
/// No more user-serviceable parts in this file.  Stop Tweaking Now!
/// 


#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioConverter.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>


#define SqueakFrameSize	4	// guaranteed (see class SoundPlayer)
#define DeviceFrameSize	8	// ditto (<CoreAudio/AudioHardware.h>, para 9)

char empty[256] = { 0 };

#define DEBUG	0
#define TESTING	0

#if (!TESTING)
# include "sq.h"
#else
   inline sqInt signalSemaphoreWithIndex(sqInt sema) { return 0; }
   inline sqInt success(sqInt flag) { return 0; }
   inline sqInt primitiveFail(void) { return -1; }
#endif

#include "sqMacUnixInterfaceSound.h"

char		*dpyPixels  = 0;
sqInt		 dpyPitch   = 0;
sqInt		noSoundMixer = 0;

#if (DEBUG)

void dumpFormat(AudioStreamBasicDescription *fmt); // atend

void
dprintf(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vprintf(fmt, ap);
  va_end(ap);
}

#else // !DEBUG
void
dumpFormat(AudioStreamBasicDescription *fmt) {
 #pragma unused(fmt)
 }
 #define  dprintf(ARGS, ...)
 // inline void dprintf(const char *fmt, ...) {}

#endif // !DEBUG
void
eprintf(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
}

/* N.B. static qualifier is important for clang which won't inline these two
 * functions otherwise.
 */
static inline sqInt min(sqInt i, sqInt j) { return (i < j) ? i : j; }
static inline sqInt max(sqInt i, sqInt j) { return (i > j) ? i : j; }

// Apple error codes are really (rather contrived) 4-byte chars with
// (almost) meaningful content.
// 
char *
str4(UInt32 chars)
{
  static char str[5];
  *(sqInt *)&str= chars;
  str[4]= '\0';
  return str;
}

sqInt
checkError(OSStatus err, char *op, char *param)
{
  if (kAudioHardwareNoError != noErr)
    {
      eprintf("sound: %s(%s): error %ld (%s)\n", op, param, err, str4(err));
      return 1;
    }
  return 0;
}


/// 
/// (ring) Buffer -- a FIFO of bytes
/// 


typedef struct
{
  char *data;
  sqInt   size;	// capacity
  sqInt   avail;	// available data (not available space)
  sqInt   iptr;	// next position to write
  sqInt   optr;	// next position to read
} Buffer;


// allocate a new, empty buffer
// 
Buffer *
Buffer_new(sqInt size)
{
  Buffer *b= (Buffer *)malloc(sizeof(Buffer));
  if (!b)
    return 0;
  if (!(b->data= (char *)malloc(size)))
    {
      free(b);
      return 0;
    }
  b->size=  size;
  b->avail= 0;
  b->iptr=  0;
  b->optr=  0;
  return b;
}

// deallocate a buffer
// 
void
Buffer_delete(Buffer *b)
{
  assert(b && b->data);
  free(b->data);
  b->data = NULL;
  free(b);
}

// answer how many bytes are available for reading
// 
sqInt
Buffer_avail(Buffer *b) { return b->avail; }

// answer how many bytes can be written
// 
sqInt
Buffer_free(Buffer *b) { return b->size - Buffer_avail(b); }

// set outputs to address and size of zero (empty), one (contiguous) or two
// (wrapped, fragmented) populated regions in the buffer
// 
sqInt
Buffer_getOutputPointers(Buffer *b, char **p1, sqInt *n1, char **p2, sqInt *n2)
{
  sqInt optr=     b->optr;
  sqInt avail=    Buffer_avail(b);
  sqInt headroom= b->size - optr;
  if (avail == 0)
    {
      *p1=			*p2= 0;
      *n1=			*n2= 0;
      return 0;
    }
  else if (avail <= headroom)
    {
      *p1= b->data + optr;	*p2= 0;
      *n1= avail;		*n2= 0;
      return 1;
    }
  else
    {
      *p1= b->data + optr;	*p2= b->data;
      *n1= headroom;		*n2= avail - headroom;
      return 2;
    }
}

// set the output to the current read position and answer the amount of
// data at that location
// 
sqInt
Buffer_getOutputPointer(Buffer *b, char **ptr)
{
  sqInt optr=     b->optr;
  sqInt avail=    Buffer_avail(b);
  sqInt headroom= b->size - optr;
  if (headroom < avail) avail= headroom;
  assert((optr + avail) <= b->size);
  *ptr= b->data + optr;
  return avail;
}

// set the output to the current write location and answer the number of
// bytes that can be written to that location
// 
sqInt
Buffer_getInputPointer(Buffer *b, char **ptr)
{
  sqInt iptr=     b->iptr;
  sqInt nfree=    Buffer_free(b);
  sqInt headroom= b->size - iptr;
  if (headroom < nfree) nfree= headroom;
  assert((iptr + nfree) <= b->size);
  *ptr= b->data + iptr;
  return nfree;
}

// increment the output pointer over a contiguous section of buffer
// 
void
Buffer_advanceOutputPointer(Buffer *b, sqInt size)
{
  sqInt optr=  b->optr;
  sqInt avail= b->avail;
  optr+=  size;
  avail-= size;
  assert(optr <= b->size);
  assert(avail >= 0);
  if (optr == b->size) optr= 0;
  b->optr=  optr;
  b->avail= avail;
}

// advance the input pointer over a contiguous section of buffer
// 
void
Buffer_advanceInputPointer(Buffer *b, sqInt size)
{
  sqInt iptr= b->iptr;
  sqInt nfree= Buffer_free(b);
  nfree -= size;
  assert(nfree >= 0);
  iptr += size;
  assert(iptr <= b->size);
  if (iptr == b->size) iptr= 0;
  b->iptr= iptr;
  b->avail += size;
}

// clear the given number of bytes at the input position and advance the
// input pointer past them
// 
void
Buffer_prefill(Buffer *b, sqInt bytes)
{
  char *ptr;
  sqInt   size= Buffer_getInputPointer(b, &ptr);
  assert(bytes <= size);
  memset(ptr, 0, size);
  Buffer_advanceInputPointer(b, bytes);
}

// write at most nbytes from buf into the buffer, wrapping in the middle if
// necessary.  answer the actual number of bytes written.
// 
sqInt
Buffer_write(Buffer *b, char *buf, sqInt nbytes)
{
  sqInt iptr= b->iptr;
  sqInt bytesToCopy= min(nbytes, Buffer_free(b));
  sqInt headroom= b->size - iptr;
  sqInt bytesCopied= 0;

  if (bytesToCopy >= headroom)
    {
      memcpy(b->data + iptr, buf, headroom);
      iptr= 0;
      bytesCopied += headroom;
      bytesToCopy -= headroom;
    }
  if (bytesToCopy)
    {
      memcpy(b->data + iptr, buf + bytesCopied, bytesToCopy);
      iptr += bytesToCopy;
      bytesCopied += bytesToCopy;
    }
  b->iptr= iptr;
  b->avail += bytesCopied;
  assert(b->avail <= b->size);
  return bytesCopied;
}

sqInt
Buffer_writeRecheck(Buffer *b, char *buf, sqInt nbytes)
{
  sqInt iptr= b->iptr;
  sqInt bytesToCopy= min(nbytes, Buffer_free(b));
  sqInt headroom= b->size - iptr;
  sqInt bytesCopied= 0;

  if (b->data == NULL || buf == NULL) 
	return 0;
  
  if (bytesToCopy >= headroom)
    {
      memcpy(b->data + iptr, buf, headroom);
      iptr= 0;
      bytesCopied += headroom;
      bytesToCopy -= headroom;
    }
  if (bytesToCopy)
    {
      memcpy(b->data + iptr, buf + bytesCopied, bytesToCopy);
      iptr += bytesToCopy;
      bytesCopied += bytesToCopy;
    }
  b->iptr= iptr;
  b->avail += bytesCopied;
  assert(b->avail <= b->size);
  return bytesCopied;
}

// read at most nbytes from the buffer into buf, wrapping in the middle if
// necessary.  answer the actual number of bytes read.
// 
sqInt
Buffer_read(Buffer *b, char *buf, sqInt nbytes)
{
  sqInt optr= b->optr;
  sqInt bytesToCopy= min(nbytes, Buffer_avail(b));
  sqInt headroom= b->size - optr;
  sqInt bytesCopied= 0;

  if (bytesToCopy >= headroom)
    {
      memcpy(buf, b->data + optr, headroom);
      optr= 0;
      bytesToCopy -= headroom;
      bytesCopied += headroom;
      if (bytesToCopy)
	{
	  memcpy(buf + bytesCopied, b->data, bytesToCopy);
	  optr= bytesToCopy;
	  bytesCopied += bytesToCopy;
	}
    }
  else
    {
      memcpy(buf, b->data + optr, bytesToCopy);
      optr += bytesToCopy;
      bytesCopied= bytesToCopy;
    }
  b->optr= optr;
  b->avail -= bytesCopied;
  return bytesCopied;
}


/// 
/// Stream -- abstraction over CoreAudio devices and streams
/// 


typedef struct Stream
{
  AudioDeviceID		 id;			// associated with this stream
  sqInt			 direction;		// 1nput/0utput
  sqInt			 sampleRate;		// Squeak frames per second
  sqInt			 channels;		// channels per Squeak frame
  sqInt			 devBufSize;		// bytes per device buffer
  sqInt			 imgBufSize;		// bytes per Squeak buffer
  sqInt			 cvtBufSize;		// bytes per converter buffer
  Buffer		*buffer;		// fifo
  AudioConverterRef	 converter;		// frame format converter
  sqInt			 semaphore;		// ping me!
  u_int64_t		 timestamp;		// nominal buffer tail time (uSecs)
} Stream;


 Stream *output= 0;
 Stream *input=  0;


// tell the SoundPlayer that output can be written.
//
 void ioProcSignal(sqInt semaphore);
  void ioProcSignal(sqInt semaphore)
{
  if (semaphore)
    signalSemaphoreWithIndex(semaphore);
}


 OSStatus bufferDataProc(AudioConverterRef inAudioConverter, UInt32 *ioDataSize, void  **outData, void  *context);
  OSStatus bufferDataProc(AudioConverterRef inAudioConverter, UInt32 *ioDataSize, void  **outData, void  *context)
{
#pragma unused(inAudioConverter)

  Stream *s= (Stream *)context;
  Buffer *b= s->buffer;
  char *p1, *p2;
  sqInt   n1,  n2;
  Buffer_getOutputPointers(b, &p1, &n1, &p2, &n2);
  if (!n1)
    {
      *ioDataSize= min(256, *ioDataSize);
      *outData= (void *)empty;
#    if (DEBUG)
      putchar('-');  fflush(stdout);
#    endif
    }
  else
    {
      *ioDataSize= n1= min(n1, *ioDataSize);
      *outData= (void *)p1;
      Buffer_advanceOutputPointer(b, n1);
#     if (DEBUG)
      putchar('+');  fflush(stdout);
#     endif
    }
  return kAudioHardwareNoError;
}


 OSStatus ioProcOutput(AudioDeviceID	    device,
			     const AudioTimeStamp  *currentTime,
			     const AudioBufferList *inputData,
			     const AudioTimeStamp  *inputTime,
			     AudioBufferList	   *outputData,	// io param
			     const AudioTimeStamp  *outputTime,
			     void		   *context);
				 
// shipout to device (usually 512 frames at 44k1 for builtin audio and
// USB).  this is asynchronous and runs (implicitly) in its own thread.
// 
 OSStatus ioProcOutput(AudioDeviceID	    device,
			     const AudioTimeStamp  *currentTime,
			     const AudioBufferList *inputData,
			     const AudioTimeStamp  *inputTime,
			     AudioBufferList	   *outputData,	// io param
			     const AudioTimeStamp  *outputTime,
			     void		   *context)
{
#pragma unused(device,currentTime,inputData,inputTime,outputTime)
  Stream *s= (Stream *)context;
  Buffer *b= s->buffer;
  if (Buffer_free(b) >= s->imgBufSize)
    ioProcSignal(s->semaphore);		// restart SoundRecorder
  return AudioConverterFillBuffer(((Stream *)context)->converter, bufferDataProc, context,
				  &outputData->mBuffers[0].mDataByteSize,
				  outputData->mBuffers[0].mData);
}


// shipin from device (usually 512 frames at 44k1).  this is asynchronous and
// runs (implicitly) in its own thread.
// 
 OSStatus ioProcInput(AudioDeviceID	    device,
			    const AudioTimeStamp  *currentTime,
			    const AudioBufferList *inputData,
			    const AudioTimeStamp  *inputTime,
			    AudioBufferList	   *outputData,	// io param
			    const AudioTimeStamp  *outputTime,
			    void		   *context);
				
OSStatus ioProcInput(AudioDeviceID	    device,
			    const AudioTimeStamp  *currentTime,
			    const AudioBufferList *inputData,
			    const AudioTimeStamp  *inputTime,
			    AudioBufferList	   *outputData,	// io param
			    const AudioTimeStamp  *outputTime,
			    void		   *context)
{
#pragma unused(device,currentTime,inputTime,outputData,outputTime)

  Stream *s= (Stream *)context;
  Buffer *b= s->buffer;
  sqInt     n= Buffer_free(b);
  if ((UInt32) n >= inputData->mBuffers[0].mDataByteSize)
    Buffer_writeRecheck(b, inputData->mBuffers[0].mData, inputData->mBuffers[0].mDataByteSize);
  if (Buffer_avail(b) >= s->imgBufSize)
    ioProcSignal(s->semaphore);		// restart SoundRecorder
  return kAudioHardwareNoError;
}


 sqInt getDefaultDevice(AudioDeviceID *id, sqInt direction);
sqInt getDefaultDevice(AudioDeviceID *id, sqInt direction)
{
  UInt32 sz= sizeof(*id);
  return (!checkError(AudioHardwareGetProperty((direction
						? kAudioHardwarePropertyDefaultInputDevice
						: kAudioHardwarePropertyDefaultOutputDevice),
					       &sz, (void *)id),
		      "GetProperty", (direction ? "DefaultInput" : "DefaultOutput")));
}


// allocate and a Stream and associate it with a suitable device.
//
 Stream *Stream_new(sqInt dir);
Stream *Stream_new(sqInt dir)
{
  AudioDeviceID id= 0;
  Stream       *s=  0;

  if (!getDefaultDevice(&id, dir))
    return 0;	// no device available

  if (!(s= (Stream *)calloc(1, sizeof(Stream))))
    {
      eprintf("out of memory");
      return 0;
    }
  s->id=	id;
  s->direction= dir;
  dprintf("stream %p[%d] created for device %ld\n", s, dir, id);

  return s;
}


// deallocate a Stream.
//
 void Stream_delete(Stream *s);
void Stream_delete(Stream *s)
{
  assert(s && s->buffer);
  Buffer_delete(s->buffer);
  dprintf("stream %p[%d] deleted\n", s, s->direction);
  free(s);
}


// setup conversion from Squeak to device frame format, or vice-versa.
// requires: stereo for output, stereo or mono for input.
//
 sqInt Stream_setFormat(Stream *s, sqInt frameCount, sqInt sampleRate, sqInt stereo);
sqInt Stream_setFormat(Stream *s, sqInt frameCount, sqInt sampleRate, sqInt stereo)
{
  sqInt nChannels=	1 + stereo;
  AudioStreamBasicDescription imgFmt, devFmt;
  UInt32 sz= sizeof(devFmt);

  if (0 == s->direction) nChannels= 2;	// insist

  if (checkError(AudioDeviceGetProperty(s->id, 0, s->direction,
					kAudioDevicePropertyStreamFormat,
					&sz, &devFmt),
		 "GetProperty", "StreamFormat"))
    return 0;

  dprintf("stream %p[%d] device format:\n", s, s->direction);  dumpFormat(&devFmt);

  imgFmt.mSampleRate	   = sampleRate;
  imgFmt.mFormatID	   = kAudioFormatLinearPCM;
  imgFmt.mFormatFlags	   = kAudioFormatFlagsNativeEndian | kLinearPCMFormatFlagIsSignedInteger;
  imgFmt.mBytesPerPacket   = SqueakFrameSize / (3 - nChannels);
  imgFmt.mFramesPerPacket  = 1;
  imgFmt.mBytesPerFrame    = SqueakFrameSize / (3 - nChannels);
  imgFmt.mChannelsPerFrame = nChannels;
  imgFmt.mBitsPerChannel   = 16;

  dprintf("stream %p[%d] image format:\n", s, s->direction);  dumpFormat(&imgFmt);

  if (s->direction) // input
    {
      if (checkError(AudioConverterNew(&devFmt, &imgFmt, &s->converter), "AudioConverter", "New"))
	return 0;
      sz= sizeof(s->cvtBufSize);
      s->cvtBufSize= 512 * devFmt.mBytesPerFrame;
      if (checkError(AudioConverterGetProperty(s->converter, kAudioConverterPropertyCalculateOutputBufferSize,
					       &sz, &s->cvtBufSize), 
		     "GetProperty", "OutputBufferSize"))
	return 0;
    }
  else // output
    {
      if (checkError(AudioConverterNew(&imgFmt, &devFmt, &s->converter), "AudioConverter", "New"))
	return 0;
    }

  s->channels=   nChannels;
  s->sampleRate= sampleRate;
  s->imgBufSize= SqueakFrameSize * nChannels * frameCount;

  frameCount= max(frameCount, 512 * sampleRate / devFmt.mSampleRate);

  s->buffer= Buffer_new((s->direction ? DeviceFrameSize : SqueakFrameSize) * nChannels * frameCount * 2);

  dprintf("stream %p[%d] sound buffer size %d/%d (%d)\n", s, s->direction, s->imgBufSize, s->buffer->size, frameCount);

  return 1;
}


// start the device attached to the stream.
// 
 sqInt Stream_startSema(Stream *s, sqInt semaIndex);
  sqInt Stream_startSema(Stream *s, sqInt semaIndex)
{
  AudioDeviceIOProc ioProc= s->direction ? ioProcInput : ioProcOutput;

  dprintf("stream %p[%d] startSema: %d\n", s, s->direction, semaIndex);
  
  s->semaphore= semaIndex;	// can be zero
  if (checkError(AudioDeviceAddIOProc(s->id, ioProc, (void *)s),
		 "Add", "ioProcOut"))
    return 0;
  if (checkError(AudioDeviceStart(s->id, ioProc),
		 "DeviceStart", "ioProcOut"))
    {
      AudioDeviceRemoveIOProc(s->id, ioProc);
      return 0;
    }
  dprintf("stream %p[%d] running\n", s, s->direction);
  return 1;
}


// stop the device attached to a stream.
// 
 sqInt Stream_stop(Stream *s);
sqInt Stream_stop(Stream *s)
{
  AudioDeviceIOProc ioProc= s->direction ? ioProcInput : ioProcOutput;
  checkError(AudioDeviceStop(s->id, ioProc),
	     "DeviceStop", s->direction ? "ioProcIn" : "ioProcOut");
  checkError(AudioDeviceRemoveIOProc(s->id, ioProc),
	     "Remove", s->direction ? "ioProcIn" : "ioProcOut");
  dprintf("stream %p[%d] stopped\n", s, s->direction);
  return 1;
}


/// 
/// sound output primitives
/// 

 sqInt sound_AvailableSpace(void);
 
 sqInt sound_AvailableSpace(void)
{
  if (output)
    return Buffer_free(output->buffer);
  success(false);
  return 8192;	// so that older images can cope
}


// mix nFrames of samples into an output buffer.
// 
 void mixFrames(short *out, short *in, sqInt nFrames);
 
 void mixFrames(short *out, short *in, sqInt nFrames)
{
  while (nFrames--)
    {
      sqInt sample;
      sample= (sqInt)*out + (sqInt)*in++;  *out++= (short)max(-32768, min(32767, sample));
      sample= (sqInt)*out + (sqInt)*in++;  *out++= (short)max(-32768, min(32767, sample));
    }
}


// insert up to frameCount (and no less than frameCount/2 -- see SoundPlayer
// class>>startPlayingImmediately: for the [bogus] reasons why) frames into
// the front and back buffers, leaving some number of framesOfLeadTime
// intact before starging the insertion.  (this last parameter is
// meaningless for us and could be reduced to zero, but ignoring it causes
// strange things to happen.  time to rething the image code, methinks.)
// 
// Note: this is only used when the "sound quick start" preference is
// enabled in the image.
// 
 sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, void* srcBufPtr,
				  sqInt framesOfLeadTime)
{
#pragma unused(framesOfLeadTime)
  Stream *s= output;

  dprintf("snd_InsertSamples %d From %p LeadTime %d\n", frameCount, srcBufPtr, framesOfLeadTime);

  if (s)
    {
      // data already sent to the device is lost forever, although latency
      // is only a few hundred frames (and is certainly much lower than the
      // standard value of `framesOfLeadTime').  instead of putzing around
      // why not just mix the samples in right away, leaving one h/w
      // buffer's worth of lead time in case we're interrupted in the
      // middle?

      char *frontData=   0, *backData=   0;
      sqInt   frontFrames= 0,  backFrames= 0;
      sqInt   framesDone=  0;
      sqInt   leadBytes;

#    if (OBEY_LEAD_TIME)
      {
	AudioTimeStamp timeStamp;
	u_int64_t      then, now;

	timeStamp.mFlags= kAudioTimeStampHostTimeValid;
	checkError(AudioDeviceGetCurrentTime(s->id, &timeStamp),
		   "AudioDeviceGetCurrentTime", "");
	now= AudioConvertHostTimeToNanos(timeStamp.mHostTime) / 1000ull;
	then= s->timestamp;
	leadBytes= ( ((now - then) * (u_int64_t)s->sampleRate) / 1000000ull
		     + framesOfLeadTime ) * SqueakFrameSize;
      }
#    else
      {
	leadBytes= s->devBufSize;	// quantum shipped to the hardware
      }
#    endif

      {
	sqInt   availBytes;
	sqInt   byteCount= frameCount * SqueakFrameSize;
	Buffer_getOutputPointers(s->buffer,
				 &frontData, &frontFrames,	// bytes!
				 &backData,  &backFrames);	// bytes!
	availBytes= frontFrames + backFrames;
	// don't consume more than frameCount - 1 frames
	leadBytes= max(leadBytes, availBytes - byteCount + SqueakFrameSize);

	assert((availBytes - leadBytes) <  (byteCount));

	if (leadBytes < frontFrames)	// skip leadBytes into first fragment
	  {
	    frontData   += leadBytes;
	    frontFrames -= leadBytes;
	  }
	else				// omit the first fragment
	  {
	    leadBytes -= frontFrames;	// lead in second fragment
	    frontFrames= 0;
	    backData   += leadBytes;	// skip leadBytes into second fragment
	    backFrames -= leadBytes;
	  }
	frontFrames /= SqueakFrameSize;
	backFrames  /= SqueakFrameSize;
      }

      assert((frontFrames + backFrames) < frameCount);	// avoid bug in image

      if ((frontFrames + backFrames) >= (frameCount / 2))
	{
	  mixFrames((short *)frontData, (short *)srcBufPtr, frontFrames);
	  srcBufPtr += frontFrames * SqueakFrameSize;
	  mixFrames((short *)backData,  (short *)srcBufPtr, backFrames);
	  framesDone= frontFrames + backFrames;
	}
      return framesDone;
    }

  success(false);
  return frameCount;
}


// play (exactly) frameCount of samples (and no less, since the result is
// ignored).
// 

  sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, void* arrayIndex, sqInt startIndex)
{
  if (output)
    {
      sqInt byteCount= frameCount * SqueakFrameSize;
      if (Buffer_free(output->buffer) >= byteCount)
	{
	  Buffer_write(output->buffer,
		       (char *)arrayIndex + (startIndex * SqueakFrameSize),
		       byteCount);
	  return frameCount;
	}
      return 0;
    }
  success(false);
  return 8192;
}


// play a buffer's worth of silence (as quietly as possible).
// 
 sqInt sound_PlaySilence(void);
 sqInt sound_PlaySilence(void)
{
  success(false);
  return 8192;
}


// shut down sound output.
// 
 sqInt sound_Stop(void);
 sqInt sound_Stop(void)
{
  dprintf("snd_Stop\n");
  
  if (output)
    {
      Stream_stop(output);
      Stream_delete(output);
      output= 0;
    }
  return 1;
}


// start up sound output.
// 
 sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
 sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  Stream *s= 0;

  dprintf("snd_Start frames: %d samplesPerSec: %d stereo: %d semaIndex: %d\n",
	   frameCount, samplesPerSec, stereo, semaIndex);
  
  if (output)	// there might be a change of sample rate
    sound_Stop();

  if ((s= Stream_new(0)))	// 0utput
    {
      if ((  Stream_setFormat(s, frameCount, samplesPerSec, stereo))
	  && Stream_startSema(s, semaIndex))
	{
	  output= s;
	  return 1;
	}
      Stream_delete(s);
    }
  return primitiveFail();
}


/// 
/// sound input
/// 


// answer the input sample rate.  (this is guaranteed to be the same
// as the sample rate that was requested.)
// 
 double sound_GetRecordingSampleRate(void);
 double sound_GetRecordingSampleRate(void)
{
  if (input)
    return (double)input->sampleRate;	//xxx FIXME: this should be FP

  primitiveFail();
  return 0.0L;
}


 sqInt sound_StopRecording(void);
  sqInt sound_StopRecording(void)
{
  dprintf("snd_StopRecording\n");

  if (input)
    {
      Stream_stop(input);
      Stream_delete(input);
      input= 0;
    }
  return 1;
}


// start up sound input.
// 
 sqInt sound_StartRecording(sqInt samplesPerSec, sqInt stereo, sqInt semaIndex);
 sqInt sound_StartRecording(sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  Stream *s= 0;

  dprintf("snd_StartRecording rate: %d stereo: %d semaIndex: %d\n",
	   samplesPerSec, stereo, semaIndex);
  
  if (input)	// there might be a change of sample rate
    sound_StopRecording();

  if ((s= Stream_new(1)))	// 1nput
    {
      // approximate the frameCount that output uses for the same sample rate
      sqInt frameCount= 5288 * samplesPerSec / 44100;
      if ((  Stream_setFormat(s, frameCount, samplesPerSec, stereo))
	  && Stream_startSema(s, semaIndex))
	{
	  input= s;
	  return 1;
	}
      Stream_delete(s);
    }
  return primitiveFail();
}


 sqInt sound_RecordSamplesIntoAtLength(void * buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  if (input)
    {
      if (Buffer_avail(input->buffer) >= (512 * DeviceFrameSize))
	{
	  sqInt    start= startSliceIndex * SqueakFrameSize / 2;
	  sqInt count= min(input->cvtBufSize, bufferSizeInBytes);
		if (count <= 0) {
			success(false);
			return 0;
		}
	  if (kAudioHardwareNoError == AudioConverterFillBuffer(input->converter, bufferDataProc, input,
								&count, (char *)buf + start))
	    return count / (SqueakFrameSize / 2) / input->channels;
	}
      return 0;
    }
  success(false);
  return 0;
}


/// 
/// mixer
/// 


 sqInt getVolume(sqInt dir, double *left, double *right);
 sqInt getVolume(sqInt dir, double *left, double *right)
{
  UInt32	sz;
  AudioDeviceID	id;
  Float32	chan1, chan2;

  if (!getDefaultDevice(&id, dir))
    return 0;

  sz= sizeof(chan1);
  if (checkError(AudioDeviceGetProperty(id, 1, // left
					dir, kAudioDevicePropertyVolumeScalar,
					&sz, &chan1),
		 "GetProperty", "VolumeScalar"))
    return 0;
  sz= sizeof(chan2);
  if (checkError(AudioDeviceGetProperty(id, 2, // right
					dir, kAudioDevicePropertyVolumeScalar,
					&sz, &chan2),
		 "GetProperty", "VolumeScalar"))
    chan2= chan1;
  
  *left=  chan1;
  *right= chan2;

  return 1;
}


 sqInt setVolume(sqInt dir, double dleft, double dright);
 sqInt setVolume(sqInt dir, double dleft, double dright)
{
  Float32 left=  (Float32)dleft;
  Float32 right= (Float32)dright;
  UInt32	 sz;
  AudioDeviceID	 id;

  if (!getDefaultDevice(&id, dir))
    return 0;

  sz= sizeof(left);
  if (checkError(AudioDeviceSetProperty(id, 0, 1, // left
					dir, kAudioDevicePropertyVolumeScalar,
					sz, &left),
		 "SetProperty", "VolumeScalar"))
    return 0;

  sz= sizeof(right);
  if (checkError(AudioDeviceSetProperty(id, 0, 2, // right
					dir, kAudioDevicePropertyVolumeScalar,
					sz, &right),
		 "SetProperty", "VolumeScalar"))
    return 0;

  return 1;
}


// get output gain, 0.0 <= { left, right } <= 1.0
// 
 void sound_Volume(double *left, double *right);
 void sound_Volume(double *left, double *right)
{
  getVolume(0, left, right);
}


// set output gain, 0.0 <= { left, right } <= 1.0
// 
 void sound_SetVolume(double left, double right);
 void sound_SetVolume(double left, double right)
{
  extern sqInt noSoundMixer;	//xxx FIXME: this should not be a global option

  if (noSoundMixer)
    return;

  setVolume(0, left, right);
}


// set recording gain, 0 <= level <= 1000
// 
 sqInt sound_SetRecordLevel(sqInt level);
 sqInt sound_SetRecordLevel(sqInt level)
{
  extern sqInt noSoundMixer;

  if (noSoundMixer)
    return 0;

  return setVolume(1, (double)level / 1000.0L, (double)level / 1000.0L);
}


/// 
/// debugging
/// 


#if (DEBUG)

void
dumpFormat(AudioStreamBasicDescription *fmt)
{
  UInt32 flags= fmt->mFormatFlags;

  printf("  sample rate         %g\n",	fmt->mSampleRate);
  printf("  format              %s\n",  str4(fmt->mFormatID));
  printf("  flags               %08lx",	flags);

  if	  (flags & kAudioFormatFlagIsBigEndian)		printf(" big-endian");
  else							printf(" little-endian");

  if	  (flags & kAudioFormatFlagIsFloat)		printf(" float");
  else if (flags & kAudioFormatFlagIsSignedInteger)	printf(" signed-sqInt");
  else							printf(" unsigned-sqInt");

  if	  (flags & kAudioFormatFlagIsPacked)		printf(" packed");
  else if (flags & kAudioFormatFlagIsAlignedHigh)	printf(" aligned-high");
  else							printf(" aligned-low");

  if	  (flags & kAudioFormatFlagIsNonInterleaved)	printf(" interleaved");
  else							printf(" non-interleaved");
  printf("\n");

  printf("  bytes per packet    %ld\n",	fmt->mBytesPerPacket);
  printf("  frames per packet   %ld\n",	fmt->mFramesPerPacket);
  printf("  channels per frame  %ld\n",	fmt->mChannelsPerFrame);
  printf("  bytes per frame     %ld\n",	fmt->mBytesPerFrame);
  printf("  bits per channel    %ld\n",	fmt->mBitsPerChannel);
}

#endif // (DEBUG)


#if (!TESTING)

# include "SqSound.h"

static sqInt sound_SetSwitch(sqInt id, sqInt captureFlag, sqInt parameter)
{
	return -1;
}

static sqInt sound_GetSwitch(sqInt id, sqInt captureFlag, sqInt channel)
{
	return -1;
}

static sqInt sound_SetDevice(sqInt id, char *arg)
{
	return -1;
}


  SqSoundDefine(MacOSX);

# include "SqModule.h"

  void  sound_parseEnvironment(void);
   sqInt   sound_parseArgument(sqInt argc, char **argv);
   void  sound_printUsage(void);
   void  sound_printUsageNotes(void);
   void *sound_makeInterface(void);
   void *np_sound_makeInterface(void);

	void  sound_parseEnvironment(void) {}
   sqInt   sound_parseArgument(sqInt argc, char **argv) {
	#pragma unused(argc,argv)
	return 0; }
   void  sound_printUsage(void) {}
   void  sound_printUsageNotes(void) {}
   void *sound_makeInterface(void) { return &sound_MacOSX_itf; }

  void *np_sound_makeInterface(void) { return &sound_MacOSX_itf; }

  SqModuleDefine(sound, MacOSX);

#else // TESTING

# include "math.h"

# define RATE	48000.0			// samples per second
# define FRAMES	5288 * RATE / 44100	// nominal buffer size requested by Squeak
# define FREQ	440.0			// tuning fork required to verify this ;)

 short sound[(sqInt)(FRAMES * 2)];

 void warble(sqInt n)
{
   double phase = 0.0;
   double amp   = 0.5;
   double pan   = 0.5;
   double freq  = FREQ * 2.0 * 3.14159265359 / RATE;

  short *out= sound;
  while (n--)
    {
      float wave= sin(phase) * amp;
      phase= phase + freq;
      *out++= 32767.0 * wave * (1.0-pan);	// left channel
      *out++= 32767.0 * wave * pan;		// right channel
    }
}

sqInt main()
{
  sound_Start(FRAMES, RATE, 1, 3);
  for (;;)
    {
      sqInt n= min(sizeof(sound), sound_AvailableSpace()) / 4;
      if (n)
	{
	  warble(n);
	  sound_PlaySamplesFromAtLength(n, (sqInt)sound, 0);
#        if (DEBUG)
	  putchar('.');  fflush(stdout);
#        endif
	}
      else
	usleep(1000);
    }
  (void)sound_InsertSamplesFromLeadTime;
  (void)sound_PlaySilence;
  (void)sound_GetRecordingSampleRate;
  (void)sound_StartRecording;
  (void)sound_RecordSamplesIntoAtLength;
  (void)sound_Volume;
  (void)sound_SetVolume;
  (void)sound_SetRecordLevel;
  return 0;
}

/*
  cc -g -Wall -DTESTING=1 -o sqUnixSoundMacOSX sqUnixSoundMacOSX.c -framework CoreAudio -framework AudioToolbox
*/

#endif // TESTING
