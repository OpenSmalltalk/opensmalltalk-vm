/* sqUnixSoundMacOSX.c -- sound support for CoreAudio on Mac OS 10
 *
 * Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2003-02-09 17:52:51 by piumarta on emilia.inria.fr
 *
 *   Copyright (C) 1996-2003 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
 *   All rights reserved.
 *   
 *     You are NOT ALLOWED to distribute modified versions of this file
 *     under its original name.  If you want to modify it and then make
 *     your modifications available publicly, rename the file first.
 * 
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 */

// Notes:
// 
// The image always generates stereo samples.  Since the only
// supported hardware format is stereo, I cheerfully ignore the stereo
// flag in snd_Start().  (Mixing everything down to mono only to have
// the format converter break it back into stereo seems pointless.)
// 
// BUGS:
// 
// All those primitiveFail()s are going to have to become
// interpreterProxy->success(0)s when this goes modular.
// 
// Double-buffered code (especially input) is _really_ ugly.
// 
// Stream.sampleRate should be a float.
// 
// 48 kHz sample rate is broken.
// 
// Check whether the priority nonsense is required on SMP machines.


#if (TESTING)
# define USE_AUDIO_MACOSX
#else
# include "sq.h"
#endif


#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioConverter.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <string.h>


/// 
/// Things you can tweak, should you really want to...
/// 


// Do we queue frames for output using double buffering or a FIFO?
//
#define USE_FIFO	1

// Do we obey the (huge) default "lead" time of 1024 frames (supplied
// by the image) when mixing frames into the buffer, or do we reduce
// the lead time to to an absolute (safe) minimum?
//
#define OBEY_LEAD_TIME	0

// when tracking window move or resize, the WindowServer thread (running with
// a RT priority _way_ higher than any other thread) grabs the CPU and sits in
// a tight loop hogging every available cycle, stopping user apps dead in
// their tracks (and sending the VM into a coma -- which is somewhat
// unfortunate if the SoundPlayer is running).  (In case you ever wondered,
// this why the entire screen freezes while you're dragging any window around.
// the only way that, e.g., iTunes manages to carry on is to install a time
// constrained producer thread running with almost the maximum allowed
// priority.  bravo, Apple.  [not.])  one way to counter-attack is to detect
// the onset of this rather antisocial behaviour and raise the priority of the
// VM thread (strictly for the duration of the tracking loop) just enough that
// it can preempt the WS thread in time to supply sound data before the device
// buffer underruns.  (this is INHERENTLY DANGEROUS if the VM is CPU bound
// [rather than spending most of its time waiting on the sound semaphore]
// since the WS thread runs at higher priority than our CoreAudio callback
// thread.  IOW, there's a PRIORITY INVERSION just begging to happen!)
// setting RAISE_PRIORITY to 1 enables this _disgusting_ hack.
// 
#define RAISE_PRIORITY	1

// do we attempt to RAISE_PRIORITY with pthread_setschedparam() or bypass
// it and deal directly with mach's thread_policy_set()?  (the latter is
// potentially _much_ more `violent' to the rest of the system.)
// 
#define USE_MACH_SCHED	0


/// 
/// No more user-serviceable parts in this file.  Stop Tweaking Now!
/// 


#define SqueakFrameSize	4	// guaranteed (see class SoundPlayer)
#define DeviceFrameSize	8	// ditto (<CoreAudio/AudioHardware.h>, para 9)

inline int min(int i, int j) { return (i < j) ? i : j; }
inline int max(int i, int j) { return (i > j) ? i : j; }

#include "debug.h"	// i'm tired of typing this into every file

#if (DEBUG)
static void dumpFormat(AudioStreamBasicDescription *fmt); // atend
#else
# define  dumpFormat(fmt)
#endif


// Apple error codes are really (rather contrived) 4-byte chars with
// (almost) meaningful content.
// 
static char *str4(UInt32 chars)
{
  static char str[5];
  *(int *)&str= chars;
  str[4]= '\0';
  return str;
}


static inline int checkError(OSStatus err, char *op, char *param)
{
  if (kAudioHardwareNoError != noErr)
    {
      eprintf("sound: %s(%s): error %ld (%s)\n", op, param, err, str4(err));
      return 1;
    }
  return 0;
}


#if (DEBUG)
  // this draws feedback blobs to the left of the apple icon in the menu bar
  extern void feedback(int offset, int colour);
# define RED	0xff0000
# define GREEN	0x00ff00
# define BLUE	0x0000ff
# define WHITE	0xffffff
# define BLACK	0x000000
#endif

#if (!TESTING) && (!DEBUG)
# define feedback(o,c)
#endif

#if (TESTING)
# define signalSemaphoreWithIndex(i)
# define success(b)
# define primitiveFail()	-1
  void feedback(int i,int j)	{}
#endif


#if (!RAISE_PRIORITY)

//xxx FIXME: this entire unholy mess should be in a header and declared static [inline]

# define setPriority(i)
# define resetPriority()
# define printPriority()
# define inModalLoop	0
# define priorityRaised 0

#else // (RAISE_PRIORITY)

extern int inModalLoop;

static int priorityRaised= 0;

# if (USE_MACH_SCHED)

#   include <mach/message.h>
#   include <mach/thread_policy.h>
#   include <mach/thread_switch.h>

extern kern_return_t thread_policy_get();	// commented out in the header file
extern kern_return_t thread_policy_set();

static mach_port_t vmThread= 0;


static kern_return_t getMachPriority(mach_port_t  thread,
				     int	 *priority,
				     boolean_t   *timeshared)
{
  thread_extended_policy_data_t   policy;
  thread_precedence_policy_data_t precedence;
  boolean_t			  getDefaults;
  mach_msg_type_number_t	  count;
  kern_return_t			  status= 0;

  if (0 == thread)
    thread= mach_thread_self();

  if (timeshared)
    {
      getDefaults= 0;
      count= THREAD_EXTENDED_POLICY_COUNT;
      status= thread_policy_get(thread, THREAD_EXTENDED_POLICY,
				&policy, &count, &getDefaults);
      if (!status) return status;
      *timeshared= policy.timeshare;
    }

  if (priority)
    {
      getDefaults= 0;
      count= THREAD_PRECEDENCE_POLICY_COUNT;
      status= thread_policy_get(thread, THREAD_PRECEDENCE_POLICY,
				&precedence, &count, &getDefaults);
      if (!status) return status;
      *priority= precedence.importance;
    }
  return status;
}


static kern_return_t setMachPriority(mach_port_t thread,
				     int         priority,
				     boolean_t   timeshared)
{
  thread_extended_policy_data_t    policy;
  thread_precedence_policy_data_t  precedence;
  kern_return_t                    status = 0;

  policy.timeshare= timeshared;
  precedence.importance= priority;
  if (0 == thread)
    thread= mach_thread_self();

  // setting policy can alter priority, so set policy first
  if (!(status= thread_policy_set(thread,  THREAD_EXTENDED_POLICY,
				  &policy, THREAD_EXTENDED_POLICY_COUNT)))
    status= thread_policy_set(thread,      THREAD_PRECEDENCE_POLICY,
			      &precedence, THREAD_PRECEDENCE_POLICY_COUNT);
  return status;
}


static void initPriority(void)
{
  vmThread= mach_thread_self();
}


#if UNUSED_AND_DISABLED_TO_AVOID_STUPID_COMPILER_BITCHING
static void printPriority(void)
{
  int priority, ts;
  if (!getMachPriority(0, &priority, &ts))
    printf("pri %d ts %d\n", priority, ts);
}
#endif


static void setPriority(int delta)
{
  if (inModalLoop)	// we do this ONLY when the WS is hogging all the CPU
    {
      priorityRaised= 1;
      //xxx 6 is too low (the WS thread continues to hog CPU even when
      // timeshare is off for the VM) and 7 is too high (even when timeshare
      // is on for the VM: we get CPU back from WS but then the VM switches
      // out the ioproc thread before the callback completes [and has a chance
      // to write data to the device] the moment it signals the sound
      // semaphore; the device stops responding, or loses sync and stream
      // integrity collapses)-:.  need to investigate the possibility of using
      // some kind of TC policy (which would really require cooperation
      // from checkForInterrupts, so that's definitely not for today...).
      if (setMachPriority(vmThread, 6, 1))
	printf("failed to increase priority\n");
      feedback(1, RED);
    }
}


static void resetPriority(void)
{
  if (priorityRaised)
    {
      priorityRaised= 0;
      if (setMachPriority(vmThread, 0, 1))
	printf("failed to decrease priority\n");
      feedback(1, WHITE);
    }
}


# else // (!USE_MACH_SCHED)


#   include <pthread.h>

static pthread_t	  vmThread;
static int		  vmPolicy= 0;
static struct sched_param vmParams;


static void initPriority(void)
{
  vmThread= pthread_self();
  if (pthread_getschedparam(vmThread, &vmPolicy, &vmParams))
    perror("getschedparam");
}


#if UNUSED
static void printPriority(pthread_t who)
{
  int policy;
  struct sched_param param;

  if (pthread_getschedparam(who, &policy, &param))
    perror("getschedparam");
  printf("policy is %d, priority %d\n", policy, param.sched_priority);
}
#endif


static void setPriority(int delta)
{
  if (inModalLoop)
    {
      struct sched_param param= vmParams;

      param.sched_priority+= delta;
      if (pthread_setschedparam(vmThread, SCHED_RR, &param))
	perror("setschedparam");
      priorityRaised= 1;
      feedback(1, RED);
    }
}


static void resetPriority(void)
{
  if (priorityRaised)
    {
      if (pthread_setschedparam(vmThread, vmPolicy, &vmParams))
	perror("setschedparam");
      priorityRaised= 0;
      feedback(1, WHITE);
    }
}


# endif // (!USE_MACH_SCHED)

#endif // (RAISE_PRIORITY)



/// the sound code really starts here...



#if (USE_FIFO)


/// 
/// (ring) Buffer -- a FIFO of bytes
/// 


typedef struct
{
  char *data;
  int   size;	// capacity
  int   avail;	// available data (not available space)
  int   iptr;	// next position to write
  int   optr;	// next position to read
} Buffer;


// allocate a new, empty buffer
// 
Buffer *Buffer_new(int size)
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
void Buffer_delete(Buffer *b)
{
  assert(b && b->data);
  free(b->data);
  free(b);
}

// answer how many bytes are available for reading
// 
inline int Buffer_avail(Buffer *b)
{
  assert(!(b->avail & 3));
  return b->avail;
}

// answer how many bytes can be written
// 
inline int Buffer_free(Buffer *b)
{
  return b->size - Buffer_avail(b);
}

// set outputs to address and size of zero (empty), one (contiguous) or two
// (wrapped, fragmented) populated regions in the buffer
// 
inline int Buffer_getOutputPointers(Buffer *b, char **p1, int *n1, char **p2, int *n2)
{
  int optr=     b->optr;
  int avail=    Buffer_avail(b);
  int headroom= b->size - optr;
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
inline int Buffer_getOutputPointer(Buffer *b, char **ptr)
{
  int optr=     b->optr;
  int avail=    Buffer_avail(b);
  int headroom= b->size - optr;
  if (headroom < avail) avail= headroom;
  assert((optr + avail) <= b->size);
  *ptr= b->data + optr;
  return avail;
}

// set the output to the current write location and answer the number of
// bytes that can be written to that location
// 
inline int Buffer_getInputPointer(Buffer *b, char **ptr)
{
  int iptr=     b->iptr;
  int nfree=    Buffer_free(b);
  int headroom= b->size - iptr;
  if (headroom < nfree) nfree= headroom;
  assert((iptr + nfree) <= b->size);
  *ptr= b->data + iptr;
  return nfree;
}

// increment the output pointer over a contiguous section of buffer
// 
inline void Buffer_advanceOutputPointer(Buffer *b, int size)
{
  int optr=  b->optr;
  int avail= b->avail;
  assert(!(size & 3));
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
inline void Buffer_advanceInputPointer(Buffer *b, int size)
{
  int iptr= b->iptr;
  assert(!(size & 3));
  {
    int nfree= Buffer_free(b);
    nfree -= size;
    assert(nfree >= 0);
  }
  iptr += size;
  assert(iptr <= b->size);
  if (iptr == b->size) iptr= 0;
  b->iptr= iptr;
  b->avail += size;
}

// clear the given number of bytes at the input position and advance the
// input pointer past them
// 
inline void Buffer_prefill(Buffer *b, int bytes)
{
  char *ptr;
  int   size= Buffer_getInputPointer(b, &ptr);
  assert(!(bytes & 3));
  assert(bytes <= size);
  memset(ptr, 0, size);
  Buffer_advanceInputPointer(b, bytes);
}

// write at most nbytes from buf into the buffer, wrapping in the middle if
// necessary.  answer the actual number of bytes written.
// 
inline int Buffer_write(Buffer *b, char *buf, int nbytes)
{
  int iptr= b->iptr;
  int bytesToCopy= min(nbytes, Buffer_free(b));
  int headroom= b->size - iptr;
  int bytesCopied= 0;

  assert(!(nbytes      & 3));
  assert(!(headroom    & 3));
  assert(!(bytesToCopy & 3));

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
inline int Buffer_read(Buffer *b, char *buf, int nbytes)
{
  int optr= b->optr;
  int bytesToCopy= min(nbytes, Buffer_avail(b));
  int headroom= b->size - optr;
  int bytesCopied= 0;

  assert(!(nbytes & 3));

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


#else // !USE_FIFO


/// 
/// Buffer, DBuffer -- double buffer
/// 


typedef struct Buffer
{
  enum {
    Buffer_Empty,
    Buffer_Busy,
    Buffer_Full
  }		 state;
  void		*data;
  size_t	 size;
  size_t	 position;	// read position while full
} Buffer;


// empty a buffer
// 
static void Buffer_reset(Buffer *b)
{
  b->state= Buffer_Empty;
  b->position= 0;
}

// allocate a new buffer
// 
static Buffer *Buffer_new(int size)
{
  Buffer *b;

  if (!(b= (Buffer *)calloc(1, sizeof(Buffer))))
    return 0;
  if ((b->data= (char *)calloc(1, size)))
    {
      b->size= size;
      Buffer_reset(b);
      return b;
    }
  free(b);
  return 0;
}

// deallocate a buffer
// 
static void Buffer_delete(Buffer *b)
{
  assert(b && b->data);
  free(b->data);
  free(b);
}


typedef struct DBuffer
{
  Buffer *front;	// the buffer currently doing i/o
  Buffer *back;		// the buffer currently being read/written
} DBuffer;


// allocate a new double buffer
// 
static DBuffer *DBuffer_new(int size)
{
  DBuffer *db;
  if (!(db= (DBuffer *)calloc(1, sizeof(DBuffer)))) return 0;
  if ((db->front= Buffer_new(size)))
    {
      if ((db->back= Buffer_new(size)))
	return db;
      Buffer_delete(db->front);
    }
  return 0;
}

// deallocate a double buffer
// 
static void DBuffer_delete(DBuffer *db)
{
  assert(db && db->front && db->back);
  free(db->back);
  free(db->front);
  free(db);
}


#endif // !USE_FIFO


/// 
/// Stream -- abstraction over CoreAudio devices and streams
/// 


typedef struct Stream
{
  AudioDeviceID		 id;			// associated with this stream
  int			 direction;		// 1nput/0utput
  int			 sampleRate;		// Squeak frames per second
  int			 channels;		// channels per Squeak frame
  int			 frameCount;		// frames per Squeak buffer
  int			 byteCount;		// bytes per Squeak buffer
  int			 cvtByteCount;		// bytes per conversion buffer
  int			 devFrameCount;		// frames per conversion buffer
  int			 devByteCount;		// bytes per device buffer
#if (USE_FIFO)
  Buffer		*buffer;		// fifo
#else
  DBuffer		*buffer;		// double buffer //xxx call this Buffer
#endif
  AudioConverterRef	 converter;		// frame format converter
  int			 semaphore;		// ping me!
  u_int64_t		 timestamp;		// nominal buffer tail time (uSecs)
} Stream;


static Stream *output= 0;
static Stream *input=  0;


#include "sqUnixSoundDebug.h"


// tell the SoundPlayer that output can be written.
//
static void ioProcSignal(int semaphore)
{
  if (semaphore)
    {
      signalSemaphoreWithIndex(semaphore);
      setPriority(+6);		// your kilometrage may vary
    //noteEvent("sound");	// this just worsens contention under heavy load
    }
  feedback(2, RED);
}


// when a double buffer underruns, rather than swapping the empty
// buffers (which causes bad audio artefacts if playSamples has
// already begun filling the back buffer) ship out a device buffer's
// worth of silence instead.
// 
static float *ioProcZeroOut(float *out, int nFrames)
{
  while (nFrames--)
    {
      // there's surely a nifty altivec gizmo to do this in < -3 cycles?
      *out++= 0.0f;
      *out++= 0.0f;
    }
  return out;
}


// shipout to device (usually 512 frames at 44k1 for builtin audio and
// USB).  this is asynchronous and runs (implicitly) in its own thread.
// 
static OSStatus ioProcOutput(AudioDeviceID	    device,
			     const AudioTimeStamp  *currentTime,
			     const AudioBufferList *inputData,
			     const AudioTimeStamp  *inputTime,
			     AudioBufferList	   *outputData,	// io param
			     const AudioTimeStamp  *outputTime,
			     void		   *context)
{
  Stream  *s=  	     (Stream *)context;
  int      cvtBytes= s->cvtByteCount;		// buffer bytes to consume
  int      devBytes= s->devByteCount;		// device bytes to generate
  UInt32   sz;

#if (USE_FIFO)

  Buffer *b=         s->buffer;
  char   *data;
  int     avail=     Buffer_getOutputPointer(b, &data);
  int     byteCount= s->byteCount;		// Squeak buffer size
  int     prevAvail= Buffer_avail(b);

  if (avail >= cvtBytes)
    {
      sz= devBytes;	// mDataByteSize is unreliable; force the correct size
      checkError(AudioConverterConvertBuffer(s->converter,
					     cvtBytes, data,
					     &sz, outputData->mBuffers[0].mData),
		 "AudioConverter", "ConvertBuffer");
      outputData->mBuffers[0].mDataByteSize= sz; // tell device how much to consume
      Buffer_advanceOutputPointer(b, cvtBytes);
      if ((  (inModalLoop && (Buffer_free(b) > 100)))
	  || ((prevAvail >= byteCount) && ((prevAvail - avail) < byteCount)))
	{
	  feedback(3, GREEN);
	  ioProcSignal(s->semaphore);		// restart SoundPlayer
	}
      else
	feedback(3, WHITE);
    }
  else
    {
      ioProcZeroOut(outputData->mBuffers[0].mData, s->devFrameCount);
      outputData->mBuffers[0].mDataByteSize= devBytes;
      feedback(3, RED);
      ioProcSignal(s->semaphore);		// dunno why, but this sometimes helps
    }

#else // (!USE_FIFO)

  DBuffer *db=		s->buffer;
  Buffer  *f=		db->front;		// buffer currently playing
  Buffer  *b=		db->back;
  char 	  *frontData=	f->data + f->position;
  int	   frontBytes=	f->size - f->position;

  if (Buffer_Empty == f->state)			// front buffer is empty
    switch (b->state)
      {
      case Buffer_Busy:
	eprintf("ioproc: back buffer busy -- why?\n");
	// fall through...
      case Buffer_Empty:
	ioProcZeroOut(outputData->mBuffers[0].mData, s->devFrameCount);
	outputData->mBuffers[0].mDataByteSize= devBytes;
	ioProcSignal(s->semaphore);		// dunno why, but this sometimes helps
	return kAudioHardwareNoError;

      case Buffer_Full:				// back buffer ready: swap
	b->state= Buffer_Busy;
	assert(b->position == 0);
	s->timestamp= AudioConvertHostTimeToNanos(currentTime->mHostTime) / 1000ull;
	db->back=  f;
	db->front= b;
	f= b;
	frontData=  f->data;
	frontBytes= f->size;
	assert(f->position == 0);
	ioProcSignal(s->semaphore);
	break;
      }

  assert(frontBytes);

  if (frontBytes > cvtBytes)
    f->position += cvtBytes;
  else
    {
      if (frontBytes == cvtBytes)
	Buffer_reset(f);	// empty: swap on next intr
      else
	{
	  // reassemble an entire buffer at the start of the front buffer
	  int backBytes= cvtBytes - frontBytes;
	  memcpy(f->data, frontData, frontBytes);
	  frontData= f->data;
	  Buffer_reset(f);	// now empty: swap on next intr
	  switch (b->state)
	    {
	    case Buffer_Busy:
	      eprintf("ioproc: back buffer busy -- why?\n");
	      // fall through...
	    case Buffer_Empty:	// pad with zero
	      memset(frontData + frontBytes, 0, backBytes);
	      break;
	      
	    case Buffer_Full:	// back buffer ready: swap now
	      memcpy(frontData + frontBytes, b->data, backBytes);
	      b->state= Buffer_Busy;
	      b->position= backBytes;
	      s->timestamp=
		AudioConvertHostTimeToNanos(currentTime->mHostTime) / 1000ull;
	      db->back=  f;
	      db->front= b;
	      break;
	    }
	}
      ioProcSignal(s->semaphore);
    }

  sz= devBytes;	// mDataByteSize is unreliable; force the correct size
  checkError(AudioConverterConvertBuffer(s->converter,
					 cvtBytes, frontData,
					 &sz, outputData->mBuffers[0].mData),
	     "AudioConverter", "ConvertBuffer");
  outputData->mBuffers[0].mDataByteSize= sz;	// tell device how much to consume

#endif // (!USE_FIFO)

  return kAudioHardwareNoError;
}


// shipin from device (usually 512 frames at 44k1).  this is asynchronous and
// runs (implicitly) in its own thread.
// 
static OSStatus ioProcInput(AudioDeviceID	    device,
			    const AudioTimeStamp  *currentTime,
			    const AudioBufferList *inputData,
			    const AudioTimeStamp  *inputTime,
			    AudioBufferList	   *outputData,	// io param
			    const AudioTimeStamp  *outputTime,
			    void		   *context)
{
#if 1
  Stream  *s=  	     (Stream *)context;
  int      devBytes= s->devByteCount;		// device bytes to consume
  int      cvtBytes= s->cvtByteCount;		// buffer bytes to generate
  UInt32   sz;

#if (USE_FIFO)

  Buffer *b=         s->buffer;
  char   *data;
  int     bytesFree= Buffer_getInputPointer(b, &data);

  if (bytesFree >= cvtBytes)
    {
      assert(inputData->mBuffers[0].mDataByteSize == devBytes);
      sz= cvtBytes;	// mDataByteSize is unreliable; force the correct size
      checkError(AudioConverterConvertBuffer(s->converter,
					     devBytes, inputData->mBuffers[0].mData,
					     &sz, data),
		 "AudioConverter", "ConvertBuffer");
      //outputData->mBuffers[0].mDataByteSize= sz; // tell device how much to consume
      Buffer_advanceInputPointer(b, cvtBytes);
      if (Buffer_avail(b) >= s->byteCount)
	{
	  feedback(3, GREEN);
	  ioProcSignal(s->semaphore);		// restart SoundPlayer
	}
      else
	feedback(3, WHITE);
    }

#else // (!USE_FIFO)

  DBuffer *db=		s->buffer;
  Buffer  *f=		db->front;		// buffer currently playing
  Buffer  *b=		db->back;
  char 	  *frontData=	f->data + f->position;
  int	   frontBytes=	f->size - f->position;

  if (Buffer_Empty == f->state)			// front buffer is empty
    switch (b->state)
      {
      case Buffer_Busy:
	eprintf("ioproc: back buffer busy -- why?\n");
	// fall through...
      case Buffer_Empty:
	ioProcZeroOut(outputData->mBuffers[0].mData, s->devFrameCount);
	outputData->mBuffers[0].mDataByteSize= devBytes;
	ioProcSignal(s->semaphore);		// dunno why, but this sometimes helps
	return kAudioHardwareNoError;

      case Buffer_Full:				// back buffer ready: swap
	b->state= Buffer_Busy;
	assert(b->position == 0);
	s->timestamp= AudioConvertHostTimeToNanos(currentTime->mHostTime) / 1000ull;
	db->back=  f;
	db->front= b;
	f= b;
	frontData=  f->data;
	frontBytes= f->size;
	assert(f->position == 0);
	ioProcSignal(s->semaphore);
	break;
      }

  assert(frontBytes);

  if (frontBytes > cvtBytes)
    f->position += cvtBytes;
  else
    {
      if (frontBytes == cvtBytes)
	Buffer_reset(f);	// empty: swap on next intr
      else
	{
	  // reassemble an entire buffer at the start of the front buffer
	  int backBytes= cvtBytes - frontBytes;
	  memcpy(f->data, frontData, frontBytes);
	  frontData= f->data;
	  Buffer_reset(f);	// now empty: swap on next intr
	  switch (b->state)
	    {
	    case Buffer_Busy:
	      eprintf("ioproc: back buffer busy -- why?\n");
	      // fall through...
	    case Buffer_Empty:	// pad with zero
	      memset(frontData + frontBytes, 0, backBytes);
	      break;
	      
	    case Buffer_Full:	// back buffer ready: swap now
	      memcpy(frontData + frontBytes, b->data, backBytes);
	      b->state= Buffer_Busy;
	      b->position= backBytes;
	      s->timestamp=
		AudioConvertHostTimeToNanos(currentTime->mHostTime) / 1000ull;
	      db->back=  f;
	      db->front= b;
	      break;
	    }
	}
      ioProcSignal(s->semaphore);
    }

  sz= devBytes;	// mDataByteSize is unreliable; force the correct size
  checkError(AudioConverterConvertBuffer(s->converter,
					 cvtBytes, frontData,
					 &sz, outputData->mBuffers[0].mData),
	     "AudioConverter", "ConvertBuffer");
  outputData->mBuffers[0].mDataByteSize= sz;	// tell device how much to consume

#endif // (!USE_FIFO)
#endif // 0

  return kAudioHardwareNoError;
}


static int getDefaultDevice(AudioDeviceID *id, int direction)
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
static Stream *Stream_new(int dir)
{
  AudioDeviceID id= 0;
  Stream       *s=  0;

  if (!getDefaultDevice(&id, dir))
    return 0;	// no device available
#if 0
  {
    char *name= getDeviceName(id, dir);
    if (name)
      {
	printf("device %ld: %s\n", id, name);
	free(name);
      }
  }
#endif
  if (!(s= (Stream *)calloc(1, sizeof(Stream))))
    {
      eprintf("out of memory");
      return 0;
    }
  s->id=	id;
  s->direction= dir;
  dprintf(("stream %p[%d] created for device %ld\n", s, dir, id));

  return s;
}


// deallocate a Stream.
//
static void Stream_delete(Stream *s)
{
  assert(s && s->buffer);
#if (USE_FIFO)
  Buffer_delete(s->buffer);
#else
  DBuffer_delete(s->buffer);	//xxx this should be called Buffer too
#endif
  dprintf(("stream %p[%d] deleted\n", s, s->direction));
  free(s);
}


// setup conversion from Squeak to device frame format (or vice-versa).
// requires: stereo for output.  (stereo or mono for input.)
//
static int Stream_setFormat(Stream *s, int frameCount, int sampleRate, int stereo)
{
  int byteCount= frameCount * SqueakFrameSize;
  int devBufSize, cvtBufSize;
  AudioStreamBasicDescription imgFmt, devFmt;
  UInt32 sz= sizeof(devFmt);
  int    channels= 1 + stereo;

  dprintf(("stream %p[%d] setFormat frameCount: %d sampleRate: %d stereo: %d\n",
	   s, s->direction, frameCount, sampleRate, stereo));

  s->sampleRate= sampleRate;
  if (0 == s->direction)
    channels= 2;	// insist

  // device format: LPCM F32 BE stereo at 44k1 (but it's polite to ask
  // the device anyway...)
  if (checkError(AudioDeviceGetProperty(s->id, 0, s->direction,
					kAudioDevicePropertyStreamFormat,
					&sz, &devFmt),
		 "GetProperty", "StreamFormat"))
    return 0;
  dprintf(("stream %p[%d] device format:\n", s, s->direction)); dumpFormat(&devFmt);

  // Squeak format: LPCM S16 BE stereo (or mono on input) at any sample rate
  imgFmt.mSampleRate	   = sampleRate;
  imgFmt.mFormatID	   = kAudioFormatLinearPCM;
  imgFmt.mFormatFlags	   = ( ( kLinearPCMFormatFlagIsBigEndian)
			       | kLinearPCMFormatFlagIsSignedInteger );
  imgFmt.mBytesPerPacket   = SqueakFrameSize / (3 - channels);
  imgFmt.mFramesPerPacket  = 1;
  imgFmt.mBytesPerFrame    = SqueakFrameSize / (3 - channels);
  imgFmt.mChannelsPerFrame = channels;
  imgFmt.mBitsPerChannel   = 16;
  dprintf(("stream %p[%d] converter format:\n", s, s->direction)); dumpFormat(&imgFmt);

  if (checkError(AudioConverterNew(s->direction ? &devFmt : &imgFmt,	// input : output
				   s->direction ? &imgFmt : &devFmt,	// input : output
				   &s->converter),
		 "AudioConverter", "New"))
    return 0;

  // the stream records a fixed (default) device buffer size for use in the ioProc
  sz= sizeof(devBufSize);
  if (checkError(AudioDeviceGetProperty(s->id, 0, s->direction,
					kAudioDevicePropertyBufferSize,
					&sz, &devBufSize),
		 "GetProperty", "BufferSize"))
    return 0;

  s->channels=      channels;
  s->devByteCount=  devBufSize;
  s->devFrameCount= devBufSize / DeviceFrameSize;
  dprintf(("stream %p[%d] device buffer size %d (%d frames)\n",
	   s, s->direction, s->devByteCount, s->devFrameCount));

  // the converter is buggy: if we ask it for the input buffer size it
  // would prefer by calling AuConvGetProp(CalculateInBufSize) it
  // proceeds to barf up a `bad input buffer size' in the ioproc.  ho
  // hum.  the following seems to work for *integral divisors* (or
  // multiples) of 44100.  (tested with 88200, 44100, 22050 and 11025,
  // but Your Kilometrage May Vary.  [Note: 48000 does NOT work.])

  cvtBufSize= (float)devBufSize
    * sampleRate      / devFmt.mSampleRate
    * SqueakFrameSize / devFmt.mBytesPerFrame
    / (3 - channels); // mono => 2; stereo => 1
  s->cvtByteCount= cvtBufSize;
  dprintf(("stream %p[%d] converter buffer size %d (%d channels)\n",
	   s, s->direction, cvtBufSize, s->channels));

#if (USE_FIFO)

  s->frameCount= frameCount;
  s->byteCount=  byteCount;
  dprintf(("stream %p[%d] image buffer size %d (%d)\n",
	   s, s->direction, byteCount, frameCount));
  {
    int nBufs=  byteCount / cvtBufSize + 1;
    byteCount=  cvtBufSize * nBufs;		// align on cvtBufSize
    frameCount= byteCount / SqueakFrameSize;
  }
  // the following factor can be arbitrarily high (2 just approaches double
  // buffering behaviour under heavy load) since the SoundPlayer only writes
  // when _available_ data is < 1 (Squeak) buffer.  OTOH the code allows the
  // buffer to fill to capacity (_free_ space > 1 Squeak buffer) when
  // inModalLoop (see ../../vm/sqUnixQuartz.m), so increasing the factor will
  // (dramatically) reduce the likelihood of underrun when Squeak is being
  // starved of cycles (read: when dragging windows around and the
  // WindowServer thread is hogging 100% of the CPU at a ridiculously high
  // priority) at the expense of (momentarily) increased latency.
  s->buffer= Buffer_new(byteCount * 2);

#else // (!USE_FIFO)

  // use exactly the requested frameSize (which makes life infinitely
  // simpler in insertSamples) and deal with fragmentation in the ioproc
  s->frameCount= frameCount;
  s->byteCount=  byteCount;
  s->buffer=     DBuffer_new(byteCount);

#endif // (!USE_FIFO)

  dprintf(("stream %p[%d] sound buffer size %d (%d)\n",
	   s, s->direction, byteCount, frameCount));

  // that's it.  all that's left is to start the device running.
  // 
  // Note that both buffers are left empty.  The ioproc will repeatedly
  // underrun and ship silence until the back buffer (or initial frameCount
  // worth of fifo) is filled, at which time it will immediately swap the
  // buffers and start shipping samples.  This both minimises the possibility
  // of underrun shortly after startup (since no minimum startup latency is
  // imposed on the SoundPlayer) and reduces the maximum startup latency (from
  // the SoundPlayer writing the first buffer to audio starting) to one device
  // buffer (at most 11 milliseconds at 22kHz).
#if 1
  if (0 == s->direction)
#if (USE_FIFO)
    Buffer_prefill(s->buffer, s->byteCount);
#else
    s->buffer->front->state= Buffer_Full;
#endif
#endif

  return 1;
}


// start the device attached to the stream.
// 
static int Stream_startSema(Stream *s, int semaIndex)
{
  AudioDeviceIOProc ioProc= s->direction ? ioProcInput : ioProcOutput;

  dprintf(("stream %p[%d] startSema: %d\n", s, s->direction, semaIndex));
  
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
  dprintf(("stream %p[%d] running\n", s, s->direction));
  return 1;
}


// stop the device attached to a stream.
// 
static int Stream_stop(Stream *s)
{
  AudioDeviceIOProc ioProc= s->direction ? ioProcInput : ioProcOutput;
  checkError(AudioDeviceStop(s->id, ioProc),
	     "DeviceStop", s->direction ? "ioProcIn" : "ioProcOut");
  checkError(AudioDeviceRemoveIOProc(s->id, ioProc),
	     "Remove", s->direction ? "ioProcIn" : "ioProcOut");
  dprintf(("stream %p[%d] stopped\n", s, s->direction));
  return 1;
}


/// 
/// sound output primitives
/// 


#define FAIL(X)		return (primitiveFail(), (X))

static int sound_AvailableSpace(void)
{
  if (output)
    {
#    if (USE_FIFO)
      if (0)//inModalLoop && (Buffer_free(output->buffer) > 100))
	{
	  feedback(2, BLUE);
	  return Buffer_free(output->buffer);
	}
      else if (Buffer_avail(output->buffer) <= output->byteCount)
	{
	  feedback(2, BLUE);
	  return output->byteCount;
	}
      resetPriority();
      feedback(2, GREEN);
      return 0;
#    else // (!USE_FIFO)
      switch (output->buffer->back->state)
	{
	case Buffer_Empty:
	  feedback(2, BLUE);
	  return output->byteCount;	// can write an entire buffer
	case Buffer_Full:
	  {
	    resetPriority();
	    feedback(2, GREEN);
	    return 0;
	  }
	case Buffer_Busy:
	  eprintf("back buffer is busy -- why?\n");	// this shouldn't happen
	  feedback(2, BLACK);
	  return 0;
	}
      eprintf("this cannot happen\n");
#    endif // (!USE_FIFO)
    }
  success(false);
  return 8192;	// so that older images can cope
}


// mix nFrames of samples into an output buffer.
// 
static void mixFrames(short *out, short *in, int nFrames)
{
  while (nFrames--)
    {
      int sample;
      sample= (int)*out + (int)*in++;  *out++= (short)max(-32768, min(32767, sample));
      sample= (int)*out + (int)*in++;  *out++= (short)max(-32768, min(32767, sample));
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
static int sound_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr,
				  int framesOfLeadTime)
{
  Stream *s= output;

  dprintf(("snd_InsertSamples %d From %p LeadTime %d\n",
	   frameCount, srcBufPtr, framesOfLeadTime));

  if (s)
    {
      // data already sent to the device is lost forever, although latency
      // is only a few hundred frames (and is certainly much lower than the
      // standard value of `framesOfLeadTime').  instead of putzing around
      // why not just mix the samples in right away, leaving one h/w
      // buffer's worth of lead time in case we're interrupted in the
      // middle?

      char *frontData=   0, *backData=   0;
      int   frontFrames= 0,  backFrames= 0;
      int   framesDone=  0;
      int   leadBytes;

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
	leadBytes= s->cvtByteCount;	// quantum shipped to the hardware
      }
#    endif

#    if (USE_FIFO)
      {
	int   availBytes;
	int   byteCount= frameCount * SqueakFrameSize;
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
#    else // (!USE_FIFO)
      {
	DBuffer *db=    s->buffer;
	Buffer  *front= db->front;
	Buffer  *back=  db->back;		//xxx THERE IS A RACE HERE

	if ((  (Buffer_Full == back->state))
	    && (Buffer_Busy == front->state))
	  {
	    int frontBytes=  max(0, front->size - (front->position + leadBytes));
	    frontFrames= frontBytes / SqueakFrameSize;
	    frontData=   front->data + front->size - frontBytes;
	    backFrames=  back->size / SqueakFrameSize;
	    backData=    back->data;
	  }
      }
#    endif // (!USE_FIFO)

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

  FAIL(frameCount);
}


// play (exactly) frameCount of samples (and no less, since the result is
// ignored).
// 
static int sound_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  if (output)
    {
#    if (USE_FIFO)

      int byteCount= frameCount * SqueakFrameSize;
      if (Buffer_free(output->buffer) >= byteCount)
	{
	  Buffer_write(output->buffer,
		       (char *)arrayIndex + (startIndex * SqueakFrameSize),
		       byteCount);
	  if (priorityRaised)
	    usleep(10000);
	  return frameCount;
	}
      return 0;

#    else // (!USE_FIFO)

      Buffer *b= output->buffer->back;
      assert(frameCount == output->frameCount);
      switch (b->state)
	{
	case Buffer_Empty:	// consume an entire buffer
	  {
	    //xxx startIndex is always zero
	    int   offset= startIndex * SqueakFrameSize;
	    void *data=   (void *)(arrayIndex + offset);
	    // eat noise...
	    memcpy(b->data, data, frameCount * SqueakFrameSize);
	    // ioproc can swap when ready
	    assert(b->position == 0);
	    b->state= Buffer_Full;
	    return frameCount;
	  }
	  break;

	case Buffer_Busy:
	  eprintf("back buffer busy -- why?\n");	// this shouldn't happen
	  // fall through..
	case Buffer_Full:
	  return 0;
	}
      eprintf("this cannot happen\n");

#    endif // (!USE_FIFO)
    }

  FAIL(8192);
}


// play a buffer's worth of silence (as quietly as possible).
// 
static int sound_PlaySilence(void)
{
  FAIL(8192);
}


// shut down sound output.
// 
static int sound_Stop(void)
{
  dprintf(("snd_Stop\n"));
  
  if (output)
    {
      stopSpy();
      Stream_stop(output);
      Stream_delete(output);
      output= 0;
    }
  return 1;
}


static int priorityInitialised= 0;


// start up sound output.
// 
static int sound_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex)
{
  Stream *s= 0;

  dprintf(("snd_Start frames: %d samplesPerSec: %d stereo: %d semaIndex: %d\n",
	   frameCount, samplesPerSec, stereo, semaIndex));
  
  if (!priorityInitialised)
    {
      priorityInitialised= 1;
      initPriority();
    }

  if (output)	// there might be a change of sample rate
    sound_Stop();

  if ((s= Stream_new(0)))	// 0utput
    {
      if ((  Stream_setFormat(s, frameCount, samplesPerSec, stereo))
	  && Stream_startSema(s, semaIndex))
	{
	  output= s;
	  startSpy();
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
static double sound_GetRecordingSampleRate(void)
{
  if (input)
    return (double)input->sampleRate;	//xxx FIXME: this should be FP

  primitiveFail();
  return 0.0L;
}


static int sound_StopRecording(void)
{
  dprintf(("snd_StopRecording\n"));

  if (input)
    {
      stopSpy();
      Stream_stop(input);
      Stream_delete(input);
      input= 0;
    }
  return 1;
}


// start up sound input.
// 
static int sound_StartRecording(int samplesPerSec, int stereo, int semaIndex)
{
  Stream *s= 0;

  dprintf(("snd_StartRecording rate: %d stereo: %d semaIndex: %d\n",
	   samplesPerSec, stereo, semaIndex));
  
  if (!priorityInitialised)
    {
      priorityInitialised= 1;
      initPriority();
    }

  if (input)	// there might be a change of sample rate
    sound_StopRecording();

  if ((s= Stream_new(1)))	// 1nput
    {
      // approximate the frameCount that output uses for the same sample rate
      int frameCount= 5288 * samplesPerSec / 44100;
      if ((  Stream_setFormat(s, frameCount, samplesPerSec, stereo))
	  && Stream_startSema(s, semaIndex))
	{
	  input= s;
	  startSpy();
	  return 1;
	}
      Stream_delete(s);
    }
  return primitiveFail();
}


static int sound_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes)
{
  if (input)
    {
      int start= startSliceIndex * SqueakFrameSize / 2;
      int count= bufferSizeInBytes - start;
      return Buffer_read(input->buffer, (char *)buf + start, count)
	/ (SqueakFrameSize / 2)
	/ input->channels;
    }
  FAIL(0);
}


/// 
/// mixer
/// 


static int getVolume(int dir, double *left, double *right)
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


static int setVolume(int dir, double dleft, double dright)
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
static void sound_Volume(double *left, double *right)
{
  getVolume(0, left, right);
}


// set output gain, 0.0 <= { left, right } <= 1.0
// 
static void sound_SetVolume(double left, double right)
{
  extern int noSoundMixer;	//xxx FIXME: this should not be a global option

  if (noSoundMixer)
    return;

  setVolume(0, left, right);
}


// set recording gain, 0 <= level <= 1000
// 
static int sound_SetRecordLevel(int level)
{
  extern int noSoundMixer;

  if (noSoundMixer)
    return 0;

  return setVolume(1, (double)level / 1000.0L, (double)level / 1000.0L);
}


/// 
/// debugging
/// 


#if (DEBUG)

static void dumpFormat(AudioStreamBasicDescription *fmt)
{
  UInt32 flags= fmt->mFormatFlags;

  printf("  sample rate         %g\n",	fmt->mSampleRate);
  printf("  format              %s\n",  str4(fmt->mFormatID));
  printf("  flags               %08lx",	flags);

  if	  (flags & kAudioFormatFlagIsBigEndian)		printf(" big-endian");
  else							printf(" little-endian");

  if	  (flags & kAudioFormatFlagIsFloat)		printf(" float");
  else if (flags & kAudioFormatFlagIsSignedInteger)	printf(" signed-int");
  else							printf(" unsigned-int");

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


#if (TESTING)

#include "math.h"

#define RATE	22050.0			// samples per second
#define FRAMES	5288 * RATE / 44100	// nominal buffer size requested by Squeak
#define FREQ	440.0			// tuning fork required to verify this ;)

static short sound[(int)(FRAMES * 2)];

static void warble(int n)
{
  static double phase = 0.0;
  static double amp   = 0.5;
  static double pan   = 0.5;
  static double freq  = FREQ * 2.0 * 3.14159265359 / RATE;

  short *out= sound;
  while (n--)
    {
      float wave= sin(phase) * amp;
      phase= phase + freq;
      *out++= 32767.0 * wave * (1.0-pan);	// left channel
      *out++= 32767.0 * wave * pan;		// right channel
    }
}

int main()
{
  sound_Start(FRAMES, RATE, 1, 3);
  for (;;)
    {
      int n= min(sizeof(sound), sound_AvailableSpace()) / 4;
      if (n)
	{
	  warble(n);
	  sound_PlaySamplesFromAtLength(n, (int)sound, 0);
	}
      else
	usleep(1000);
    }
}

/*
 cc -g -Wall -DTESTING=1 -o sqUnixSoundMacOSX sqUnixSoundMacOSX.c -framework CoreAudio -framework AudioToolbox
 */

#endif // TESTING




#include "SqSound.h"

SqSoundDefine(MacOSX);


#include "SqModule.h"

static void  sound_parseEnvironment(void) {}
static int   sound_parseArgument(int argc, char **argv) { return 0; }
static void  sound_printUsage(void) {}
static void  sound_printUsageNotes(void) {}
static void *sound_makeInterface(void) { return &sound_MacOSX_itf; }

SqModuleDefine(sound, MacOSX);
