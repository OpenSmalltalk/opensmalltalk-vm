/* sqUnixSoundOSS.c -- sound module for Open Sound System
 *
 * Author: Ian.Piumarta@squeakland.org
 * 
 * Last edited: 2008-04-21 14:51:45 by piumarta on emilia
 *
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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
 */

#include "sq.h"

/* The SoundPlayer playLoop does not attempt to play sounds unless at
 * least 100 frames of output space are available.  select() says
 * output space is available when one byte can be written.  Net
 * result: Squeak sits at 100% CPU thrashing between playSema wait and
 * select() signaling the playSema.  OSS does not provide any means to
 * increase the output low water mark from one byte (to 100 frames, or
 * even an entire fragment) either.  Disabling the Semaphore entirely
 * increases audio performace noticably and Squeak idles for almost
 * all of the time (consuming < 1% CPU) when only playing sound.
 * 
 * If you turn the play Semaphore back on then you should at least
 * consider also turning on `soundStopWhenDone' in the image
 * preferences, otherwise Squeak WILL eat ALL of your CPU from the
 * moment you play the first sound.
 */
#define	USE_PLAY_SEMAPHORE

#undef	DEBUG
#undef	NDEBUG

#if 0
#define	TEST_FMT	AFMT_U8		/* forced h/w format for input/output */
#define	TEST_CHANS	2		/* forced h/w channels for input/output */
#endif

#include "sqaio.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/soundcard.h>
#include <assert.h>
#include <errno.h>


#ifdef WORDS_BIGENDIAN
# define AFMT_S16_HE	AFMT_S16_BE
# define AFMT_U16_HE	AFMT_U16_BE
# define AFMT_S16_RE	AFMT_S16_LE
# define AFMT_U16_RE	AFMT_U16_LE
#else
# define AFMT_S16_HE	AFMT_S16_LE
# define AFMT_U16_HE	AFMT_U16_LE
# define AFMT_S16_RE	AFMT_S16_BE
# define AFMT_U16_RE	AFMT_U16_BE
#endif

#define ERROR(MSG) (						\
  fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, MSG)	\
)

#define PERROR(MSG) (						\
  fprintf(stderr, "%s:%d: ", __FILE__, __LINE__),		\
  perror(MSG)							\
)

#define IOCTL(FD,CMD,ARG)					\
  ((ioctl(FD, CMD, ARG) == -1) ? (PERROR(#CMD), -1) : 0)

#define min(A,B)	(((A)<(B)) ? (A) : (B))

struct dsp;

typedef int (*reader)(struct dsp *dsp, void *buffer, int nFrames);
typedef int (*writer)(struct dsp *dsp, void *buffer, int nFrames);

#ifdef DEBUG
# define PRINTF(ARGS) ((printf ARGS), fflush(stdout))
  static char *afmtName(int i);
  static char *capName(int i);
  static char *rdName(reader rd);
  static char *wrName(writer wr);
  static char *devName(int dev);
#else
# define PRINTF(ARGS)
#endif


struct format
{
  int	format;		/* internal format */
# define FMT_S	 0x0000	/* default: 16-bit, signed, native order, stereo */
# define FMT_U	 0x0001	/* unsigned */
# define FMT_E	 0x0002	/* byte-swapped */
# define FMT_8	 0x0004	/* 8-bit */
# define FMT_M	 0x0008	/* mono */
# define FMT_MAX (FMT_8 | FMT_U)
  int	channels;	/* number of channels */
  int	rate;		/* frames per second */
  int	bpf;		/* bytes per frame */
  int	fragSize;	/* bytes per fragment */
};

struct dsp
{
  char	*path;
  int	 fd;
  int	 caps;		/* capabilities */
  int	 fmts;		/* driver formats */
  struct format hw;	/* h/w frame format */
  struct format sq;	/* Squeak frame format (FMT_S or FMT_M) */
  reader read;		/* input function */
  writer write;		/* output function */
  int	 semaphore;	/* read/write semaphore */
  int	 running;
};


struct dsp dev_dsp1 = { "/dev/dsp1", -1 };
struct dsp dev_dsp  = { "/dev/dsp",  -1 };

static struct dsp *in=  0;
static struct dsp *out= 0;

static int noSoundMixer= 0;

typedef   signed char  sbyte;
typedef unsigned char  ubyte;
typedef   signed short sword;
typedef unsigned short uword;

#define CVI	sample= *in++;
#define CVIM	CVI; sample= (sample / 2) + (*in++ / 2);
#define CVU	sample^= 0x8000;
#define CVE	sample= ((sample >> 8) & 0xff) | (sample << 8);
#define CVB	sample>>= 8;
#define CVW	sample<<= 8;
#define CVO	*out++= sample;
#define CVOS	CVO CVO

#define CV__U	    CVU
#define CV_E_	        CVE
#define CV_EU	    CVU CVE
#define CVB__	            CVB
#define CVB_U	    CVU     CVB
#define CVW__	CVW
#define CVW_U	CVW CVU

static int output(struct dsp *dsp, void *buf, int frames)
{
  int m= frames * dsp->hw.bpf;
  /* try to ensure that the entire buffer is written.  (the write
     should complete fully in all cases, but some alsa drivers
     apparently don't behave quite right in write() and/or
     select().) */
  while (m)
    {
      int n= write(dsp->fd, buf, m);
      if (n < 0)
	{
	  if (errno != EAGAIN)
	    {
	      fprintf(stderr, "sound: ");
	      PERROR(dsp->path);
	      return 0;
	    }
	}
      else
	m -= n;
    }
  return frames;
}

#define outputFn(TYPE, CVT) (struct dsp *dsp, void *buf, int frames)	\
{									\
  TYPE *cvt= (TYPE *)alloca(dsp->hw.bpf * frames);			\
  register short *in= (short *)buf;					\
  register TYPE *out= cvt;						\
  register int n= frames;						\
  while (n--) { register short sample; CVT; }				\
  return output(dsp, cvt, frames);					\
}

#define    wrMM___ output
static int wrMM__U outputFn(uword, CVI  CV__U CVO);
static int wrMM_E_ outputFn(sword, CVI  CV_E_ CVO);
static int wrMM_EU outputFn(uword, CVI  CV_EU CVO);
static int wrMM8__ outputFn(sbyte, CVI  CVB__ CVO);
static int wrMM8_U outputFn(ubyte, CVI  CVB_U CVO);
static int wrMS___ outputFn(sword, CVI 	      CVOS);
static int wrMS__U outputFn(uword, CVI  CV__U CVOS);
static int wrMS_E_ outputFn(sword, CVI  CV_E_ CVOS);
static int wrMS_EU outputFn(uword, CVI  CV_EU CVOS);
static int wrMS8__ outputFn(sbyte, CVI  CVB__ CVOS);
static int wrMS8_U outputFn(ubyte, CVI  CVB_U CVOS);
static int wrSM___ outputFn(sword, CVIM       CVO);
static int wrSM__U outputFn(uword, CVIM CV__U CVO);
static int wrSM_E_ outputFn(sword, CVIM CV_E_ CVO);
static int wrSM_EU outputFn(uword, CVIM CV_EU CVO);
static int wrSM8__ outputFn(sbyte, CVIM CVB__ CVO);
static int wrSM8_U outputFn(ubyte, CVIM CVB_U CVO);
#define    wrSS___ output
static int wrSS__U outputFn(uword, CVI  CV__U CVO  CVI CV__U CVO);
static int wrSS_E_ outputFn(sword, CVI  CV_E_ CVO  CVI CV_E_ CVO);
static int wrSS_EU outputFn(uword, CVI  CV_EU CVO  CVI CV_EU CVO);
static int wrSS8__ outputFn(sbyte, CVI  CVB__ CVO  CVI CVB__ CVO);
static int wrSS8_U outputFn(ubyte, CVI  CVB_U CVO  CVI CVB_U CVO);

#undef outputFn

static writer writers[4][FMT_MAX+1]= {
  { wrSS___, wrSS__U, wrSS_E_, wrSS_EU, wrSS8__, wrSS8_U },
  { wrSM___, wrSM__U, wrSM_E_, wrSM_EU, wrSM8__, wrSM8_U },
  { wrMS___, wrMS__U, wrMS_E_, wrMS_EU, wrMS8__, wrMS8_U },
  { wrMM___, wrMM__U, wrMM_E_, wrMM_EU, wrMM8__, wrMM8_U }
};

static int input(struct dsp *dsp, void *buf, int frames)
{
  int m= frames * dsp->hw.bpf;
  int n= read(dsp->fd, buf, m);
  if (n < 0)
    {
      fprintf(stderr, "sound: ");
      PERROR(dsp->path);
      return 0;
    }
  return n / dsp->hw.bpf;
}

#define inputFn(TYPE, CVT) (struct dsp *dsp, void *buf, register int frames)	\
{										\
  register short *out= (short *)buf;						\
  register TYPE *in= (TYPE *)alloca(dsp->hw.bpf * frames);			\
  frames= input(dsp, (void *)in, frames);					\
  {										\
    register int n= frames;							\
    while (n--) { register short sample; CVT; }					\
  }										\
  return frames;								\
}

#define    rdMM___ input
static int rdMM__U inputFn(uword, CVI  CV__U CVO);
static int rdMM_E_ inputFn(sword, CVI  CV_E_ CVO);
static int rdMM_EU inputFn(uword, CVI  CV_EU CVO);
static int rdMM8__ inputFn(sbyte, CVI  CVW__ CVO);
static int rdMM8_U inputFn(ubyte, CVI  CVW_U CVO);
static int rdMS___ inputFn(sword, CVI 	      CVOS);
static int rdMS__U inputFn(uword, CVI  CV__U CVOS);
static int rdMS_E_ inputFn(sword, CVI  CV_E_ CVOS);
static int rdMS_EU inputFn(uword, CVI  CV_EU CVOS);
static int rdMS8__ inputFn(sbyte, CVI  CVW__ CVOS);
static int rdMS8_U inputFn(ubyte, CVI  CVW_U CVOS);
static int rdSM___ inputFn(sword, CVIM       CVO);
static int rdSM__U inputFn(uword, CVIM CV__U CVO);
static int rdSM_E_ inputFn(sword, CVIM CV_E_ CVO);
static int rdSM_EU inputFn(uword, CVIM CV_EU CVO);
static int rdSM8__ inputFn(sbyte, CVIM CVW__ CVO);
static int rdSM8_U inputFn(ubyte, CVIM CVW_U CVO);
#define    rdSS___ input
static int rdSS__U inputFn(uword, CVI  CV__U CVO  CVI CV__U CVO);
static int rdSS_E_ inputFn(sword, CVI  CV_E_ CVO  CVI CV_E_ CVO);
static int rdSS_EU inputFn(uword, CVI  CV_EU CVO  CVI CV_EU CVO);
static int rdSS8__ inputFn(sbyte, CVI  CVW__ CVO  CVI CVW__ CVO);
static int rdSS8_U inputFn(ubyte, CVI  CVW_U CVO  CVI CVW_U CVO);

static reader readers[4][FMT_MAX+1]= {
  { rdSS___, rdSS__U, rdSS_E_, rdSS_EU, rdSS8__, rdSS8_U },
  { rdSM___, rdSM__U, rdSM_E_, rdSM_EU, rdSM8__, rdSM8_U },
  { rdMS___, rdMS__U, rdMS_E_, rdMS_EU, rdMS8__, rdMS8_U },
  { rdMM___, rdMM__U, rdMM_E_, rdMM_EU, rdMM8__, rdMM8_U }
};

/* NOTE: The vast majority of the above functions will almost
   certainly never be used since OSS appears to guarantee support for
   at least one of AFMT_S16_NE, AFMT_S16_LE and AFMT_U8 on all cards
   regardless of the h/w capabilities [OSS Programmer's Guide,
   revision 1.11, 7 Nov 2000, page 32].  Nonetheless, we're going to
   implement every possible conversion explicitly since the first
   person with a weirdo card/driver that doesn't work as advertised is
   bound to scream and moan (loudly and in public).  The result is
   that this file is much larger and more complicated than necessary,
   but that's the price you pay for my avoiding any possibility of
   disproportionate criticism. */


/* Close dsp.
 */
static void dspClose(struct dsp *dsp)
{
  assert(dsp->fd >= 0);
  if (dsp->semaphore > 0)
    {
      aioDisable(dsp->fd);
      dsp->semaphore= 0;
      PRINTF(("sound: %s: aio disabled\n", dsp->path));
    }
  close(dsp->fd);
  dsp->fd= -1;
}


/* Open dsp for playback.  If the dsp is capable of full-duplex
 * operation and recording is currently in progress with a compatible
 * sample format then attempt to open the dsp in parallel.  (For this
 * to even be possible it is first necessary to enable the
 * `canRecordWhilePlaying' preference in the image which will
 * otherwise ensure mutual exclusion beteen sound input and output.)
 * If full-duplex is not supported (or if the current sample format is
 * incompatible) then stop recording before opening for playback.
 * Answer whether we successfully opened the device for output.
 * 
 * NOTE: for full-duplex operation we simply attempt to open the
 * device twice (O_RDONLY and O_WRONLY) which is NOT supported by all
 * versions of OSS [1].  If this fails we should try at least two
 * alternative approaches:
 * 1) close and reopen /dev/dsp with O_RDWR, and then share it between
 *    recording and playback; or, if pressed,
 * 2) find and open a shadow device /dev/dspN (N > 0).
 * Unfortunately I'm feeling too lazy to implement all that nonsense
 * today.
 * 
 * [1] http://www.opensound.com/readme/README.fullduplex.html
 */
static struct dsp *dspOpen(struct dsp *dsp, int mode)
{
  assert(dsp);
  assert(dsp->fd < 0);
  if ((dsp->fd= open(dsp->path, mode, 0)) < 0)
    {
      if (dsp == &dev_dsp)
	{
	  fprintf(stderr, "sound: ");
	  perror(dsp->path);
	}
      return 0;
    }
  PRINTF(("sound: %s: opened with mode %d\n", dsp->path, mode));

  dsp->semaphore= 0;

  ioctl(dsp->fd, SNDCTL_DSP_SETDUPLEX,  0);	/* allow this to fail silently */
  if ((  IOCTL(dsp->fd, SNDCTL_DSP_GETCAPS, &dsp->caps))
      || IOCTL(dsp->fd, SNDCTL_DSP_GETFMTS, &dsp->fmts))
    {
      /* driver is hosed */
      fprintf(stderr, "sound: %s: could not read driver capabilities\n", dsp->path);
      dspClose(dsp);
      return 0;
    }

#ifdef TEST_FMT
  dsp->fmts = TEST_FMT;
#endif

#ifdef DEBUG
  {
    int i;
    printf("sound: %s: driver formats (%x):", dsp->path, dsp->fmts);
    for (i= 1; i; i <<= 1) if (dsp->fmts & i) printf(" %s", afmtName(i));
    printf("\nsound: %s: driver capabilities (%x):", dsp->path, dsp->caps);
    for (i= 0x100; i; i <<= 1) if (dsp->caps & i) printf(" %s", capName(i));
    printf("\n");
  }
#endif

  return dsp;
}


/* Find and set a supported sample format as close as possible to
 * Squeak's native format (16-bit signed).
 * Answer whether a format was found and set.
 */
static int dspSetFormat(struct dsp *dsp)
{
  assert(dsp);
  assert(dsp->fd >= 0);

  /* find the closest driver format */
  {
    static struct { int dsp, fmt; } formats[]= {
      { AFMT_S16_HE, FMT_S         },
      { AFMT_U16_HE, FMT_U         },
      { AFMT_S16_RE, FMT_E         },
      { AFMT_U16_RE, FMT_E | FMT_U },
      { AFMT_S8,     FMT_8         },
      { AFMT_U8,     FMT_8 | FMT_U },
      { 0,           0 }
    };
    int found= -1;
    int i;
    for (i= 0;  formats[i].dsp;  ++i)
      if (dsp->fmts & formats[i].dsp)
	{
	  /* try query before set (driver format might be locked) */
	  int fmt= AFMT_QUERY;
	  PRINTF(("sound: %s: trying format %x: %s\n", dsp->path,
		  formats[i].dsp, afmtName(formats[i].dsp)));
	  if (IOCTL(dsp->fd, SNDCTL_DSP_SETFMT, &fmt))
	    fprintf(stderr, "sound: %s: could not query driver format\n", dsp->path);
	  else if (fmt == formats[i].dsp)
	    {
	      found= i;
	      break;
	    }
	  fmt= formats[i].dsp;
	  if ((ioctl(dsp->fd, SNDCTL_DSP_SETFMT, &fmt) == 0) && (fmt == formats[i].dsp))
	    {
	      found= i;
	      break;
	    }
	}
    if (found < 0)
      {
	fprintf(stderr, "sound: %s: driver has no usable sample format\n", dsp->path);
	return 0;
      }
    PRINTF(("sound: %s: selected driver format %x: %s\n", dsp->path,
	    formats[found].dsp, afmtName(formats[found].dsp)));

    dsp->hw.format= formats[found].fmt;
    dsp->hw.bpf= ((dsp->hw.format & FMT_8) ? 1 : 2);	/* bytes per sample */
  }

  /* the Squeak side is always S16_NE */
  dsp->sq.format= FMT_S;	/* until modified by dspSetChannels() */
  dsp->sq.bpf= 2;		/* bytes per sample */

  return 1;
}


/* Set the number of channels.  Answer whether a suitable number of channels was set.
 */
static int dspSetChannels(struct dsp *dsp, int nChannels)
{
  int chans= nChannels;
  PRINTF(("sound: %s: requesting %d channels\n", dsp->path, nChannels));
  assert(chans >= 1);
  assert(chans <= 2);

  dsp->sq.channels= nChannels;

  if (nChannels == 1)
    dsp->sq.format |= FMT_M;

#ifdef TEST_CHANS
  chans= TEST_CHANS;
#endif
  IOCTL(dsp->fd, SNDCTL_DSP_CHANNELS, &chans);
  if (chans != nChannels)
    {
      nChannels= ((nChannels == 2) ? 1 : 2);
      chans= nChannels;
      IOCTL(dsp->fd, SNDCTL_DSP_CHANNELS, &chans);
      if (chans != nChannels)
	{
	  fprintf(stderr, "sound: %s: could not set a suitable number of channels\n",
		  dsp->path);
	  return 0;
	}
    }
  dsp->hw.channels= chans;

  if (chans == 1) dsp->hw.format |= FMT_M;

  dsp->hw.bpf *= dsp->hw.channels;	/* samples per frame */
  dsp->sq.bpf *= dsp->sq.channels;	/* samples per frame */

  PRINTF(("sound: %s: using %d channels\n",      dsp->path, dsp->hw.channels));
  PRINTF(("sound: %s: driver: %d bytes/frame\n", dsp->path, dsp->hw.bpf));
  PRINTF(("sound: %s: squeak: %d bytes/frame\n", dsp->path, dsp->sq.bpf));

  return 1;
}


/* Set the sample rate.  Answer whether a suitable rate was set.
 */
static int dspSetSpeed(struct dsp *dsp, int speed)
{
  int arg= speed;
  dsp->sq.rate= speed;
  if (IOCTL(dsp->fd, SNDCTL_DSP_SPEED, &arg))
    {
      fprintf(stderr, "sound: %s: failed to set sample rate\n", dsp->path);
      return 0;
    }
  dsp->hw.rate= arg;
  PRINTF(("sound: %s: %d samples/sec\n", dsp->path, dsp->hw.rate));

  if (dsp->hw.rate != dsp->sq.rate)
    fprintf(stderr, "sound: %s: using %d samples/sec (requested %d)\n", dsp->path,
	    dsp->hw.rate, dsp->sq.rate);

  return 1;
}


/* Request a fragment size approximating the number of frames of lead
 * time requested by Squeak, and record the actual fragment size set
 * by the driver.  Answer whether the fragment size was successfuly
 * modified.
 */
static int dspSetFragSize(struct dsp *dsp, int nFrames, int nChannels)
{
  int fragSize= nFrames * dsp->hw.bpf;
  int i;
  for (i= 0;  fragSize;  i++) fragSize >>= 1;
  fragSize= (4 /* fragments */ << 16) | (i - 1) /* ^2 bytesPerFragment */;

  if ((  IOCTL(dsp->fd, SNDCTL_DSP_SETFRAGMENT, &fragSize))
      || IOCTL(dsp->fd, SNDCTL_DSP_GETBLKSIZE,  &fragSize))
    {
      fprintf(stderr, "sound: %s: failed to set fragment size\n", dsp->path);
      return 0;
    }
  assert(fragSize > 0);
  dsp->hw.fragSize= fragSize;
  dsp->sq.fragSize= fragSize / dsp->hw.bpf * dsp->sq.bpf;

  PRINTF(("sound: %s: fragment size set to %d (%d frames requested in %d channels)\n",
	  dsp->path, fragSize, nFrames, nChannels));

  return 1;
}


/* Set the input/output functions according to the current sq/hw
 * formats.
 */
static int dspSetConversion(struct dsp *dsp)
{
  int sm, io;
  assert(dsp->sq.format >= 0);
  assert(dsp->sq.format <= (FMT_MAX | FMT_M));
  assert(dsp->hw.format >= 0);
  assert(dsp->hw.format <= (FMT_MAX | FMT_M));
  io= dsp->hw.format & 0x7;	/* don't care about channels */
  assert(io >= 0);
  assert(io <= FMT_MAX);
  /* output */
  sm= (((dsp->sq.format & FMT_M) << 1) | (dsp->hw.format & FMT_M)) >> 3;
  assert(sm >= 0);
  assert(sm <= 3);
  dsp->write= writers[sm][io];
  assert(dsp->write != 0);
  /* input */
  sm= (((dsp->hw.format & FMT_M) << 1) | (dsp->sq.format & FMT_M)) >> 3;
  assert(sm >= 0);
  assert(sm <= 3);
  dsp->read= readers[sm][io];
  assert(dsp->read != 0);
#ifdef DEBUG
  printf("sound: input conversion: %s (%p)\n", rdName(dsp->read), dsp->read);
  printf("sound: output conversion: %s (%p)\n", wrName(dsp->write), dsp->write);
#endif /* DEBUG */
  return 1;
}


static int dspSetSemaphore(struct dsp *dsp, int semaIndex)
{
  if (semaIndex > 0)
    {
      dsp->semaphore= semaIndex;
      aioEnable(dsp->fd, (void *)dsp, AIO_EXT);
      PRINTF(("sound: %s: aio enabled, semaphore %d\n", dsp->path, dsp->semaphore));
    }
  return 1;
}


static void dspSetTrigger(struct dsp *dsp, int mask)
{
  if (dsp->caps & DSP_CAP_TRIGGER)
    {
      int triggers= 0, toggle= 0;
      IOCTL(dsp->fd, SNDCTL_DSP_GETTRIGGER, &triggers);
      toggle= triggers & ~mask;
      IOCTL(in->fd, SNDCTL_DSP_SETTRIGGER, &toggle);
      toggle= triggers | mask;
      IOCTL(in->fd, SNDCTL_DSP_SETTRIGGER, &toggle);
    }
}


static int dspGetInputSpace(struct dsp *dsp)
{
  struct audio_buf_info info;
  if (ioctl(dsp->fd, SNDCTL_DSP_GETISPACE, &info) < 0)
    {
      fprintf(stderr, "sound: %s: ", dsp->path);
      perror("GETISPACE");
      return -1;
    }
  return info.bytes;
}


static int dspGetOutputSpace(struct dsp *dsp)
{
  struct audio_buf_info info;
  if (ioctl(dsp->fd, SNDCTL_DSP_GETOSPACE, &info) < 0)
    {
      fprintf(stderr, "sound: %s: ", dsp->path);
      perror("GETOSPACE");
      return -1;
    }
  return info.bytes;
}


/*** aio ***/


static void dspHandler(int fd, void *data, int flags)
{
  struct dsp *dsp= (struct dsp *)data;
  assert(dsp != 0);
  assert(dsp->semaphore > 0);
  signalSemaphoreWithIndex(dsp->semaphore);
  aioHandle(fd, dspHandler, flags);
}


/*** sound output ***/


static sqInt sound_Stop(void)
{
  PRINTF(("sound: stop\n"));
  if (out)
    {
      if (out != in)
	{
	  dspClose(out);
	  PRINTF(("sound: %s: device closed\n", out->path));
	}
      else
	{
	  aioSuspend(out->fd, AIO_W);
	  PRINTF(("sound: %s: aio suspended\n", out->path));
	}
      out= 0;
    }
  return true;
}


static sqInt sound_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int nChannels= (stereo ? 2 : 1);
  PRINTF(("sound: start\n"));

#ifndef USE_PLAY_SEMAPHORE
  if (semaIndex > 0)
    {
      PRINTF(("sound: asynchronous output disabled\n"));
      return success(false);
    }
#endif

  if ((out= dspOpen(&dev_dsp, O_WRONLY | O_NONBLOCK)))
    {
      /* NOTE: The OSSPG says we should set fragsize immediately after
	 opening the device (before setting sampling parameters) but this
	 causes some drivers to refuse subsequent changes to the sample
	 format.  We therefore set it after the sampling parameters.
	 (This normally won't cause problems since the block size should
	 not yet have been locked by OSS.  The worst that can happen is
	 that we'll get a longer than optimal lead time if the blocking
	 size cannot be successfully changed -- which is a far lesser evil
	 than being unable to change the sample format.) */
      if ((  dspSetFormat(out))
	  && dspSetChannels(out, nChannels)
	  && dspSetSpeed(out, samplesPerSec)
	  && dspSetFragSize(out, frameCount, nChannels)
	  && dspSetConversion(out)
#        ifdef USE_PLAY_SEMAPHORE
	  && dspSetSemaphore(out, semaIndex)
#        endif
	  )
	{
	  out->running= 0;
	  return true;
	}
      sound_Stop();
    }
  PRINTF(("sound: could not start\n"));
  return false;
}


static sqInt sound_AvailableSpace(void)
{
  int bytes= 0;

  if (out)
    {
      if (!out->running)
	{
#        ifdef USE_PLAY_SEMAPHORE
	  if (out->semaphore)
	    aioHandle(out->fd, dspHandler, AIO_W);
#        endif
	  out->running= 1;
	}
      bytes= dspGetOutputSpace(out);
      if (bytes >= 0)
	/* hardware bytes -> frames -> squeak bytes */
	return bytes / out->hw.bpf * out->sq.bpf;
    }
  PRINTF(("sound: available space: 0 bytes\n"));
  return 0;
}


static sqInt sound_InsertSamplesFromLeadTime(sqInt frameCount, sqInt srcBufPtr, sqInt samplesOfLeadTime)
{
  return success(false);
}


static sqInt sound_PlaySamplesFromAtLength(sqInt frameCount, sqInt arrayIndex, sqInt startIndex)
{
  assert(out->write != 0);
  return out->write(out, pointerForOop(arrayIndex) + startIndex * out->sq.bpf, frameCount);
}


static sqInt sound_PlaySilence(void)
{
  if (!out) return success(false);
  return out->sq.fragSize;
}


/* sound input */


static sqInt sound_StopRecording(void)
{
  PRINTF(("sound: stop recording\n"));
  if (in)
    {
      if (in != out)
	{
	  dspClose(in);
	  PRINTF(("sound: %s: device closed\n", in->path));
	}
      else
	{
	  aioSuspend(in->fd, AIO_R);
	  PRINTF(("sound: %s: aio suspended\n", in->path));
	}
      in= 0;
    }
  return true;
}


static sqInt sound_StartRecording(sqInt desiredSamplesPerSec, sqInt stereo, sqInt semaIndex)
{
  int nChannels= (stereo ? 2 : 1);
  PRINTF(("sound: start recording\n"));

  if ((  (in= dspOpen(&dev_dsp1, O_RDONLY)))
      || (in= dspOpen(&dev_dsp,  O_RDONLY)))
    {
      if ((  dspSetFormat(in))
	  && dspSetChannels(in, nChannels)
	  && dspSetSpeed(in, desiredSamplesPerSec)
	  /* try for 1/10 second input latency */
	  && dspSetFragSize(in, desiredSamplesPerSec / 10, nChannels)
	  && dspSetConversion(in)
	  && dspSetSemaphore(in, semaIndex))
	{
	  dspSetTrigger(in, PCM_ENABLE_INPUT);
	  aioHandle(in->fd, dspHandler, AIO_R);
	  in->running= 0;
	  return true;
	}
      sound_StopRecording();
    }
  PRINTF(("sound: could not start recording\n"));
  return false;
}


static double sound_GetRecordingSampleRate(void)
{
  return in ? (double)in->hw.rate : 0.0l;
}


static sqInt sound_RecordSamplesIntoAtLength(sqInt buf, sqInt startSliceIndex, sqInt bufferSizeInBytes)
{
  /*PRINTF(("record %d %d %d\n", buf, startSliceIndex, bufferSizeInBytes));*/

  if (in)
    {
      /* start index is in samples (rather than bytes or frames???) */
      int frameCount= ((bufferSizeInBytes / 2) - startSliceIndex) / in->sq.channels;
      int bytesAvail= 0;
      int framesAvail= 0;
      if (in->running)
	{
	  bytesAvail= dspGetInputSpace(in);
	  if (bytesAvail <= 0)
	    return 0;		/* underrun */
	}
      else /* initial read required to start recording on some devices */
	{
	  bytesAvail= in->hw.fragSize;
	  in->running= 1;
	}
      assert(bytesAvail > 0);
      framesAvail= bytesAvail / in->hw.bpf;
      frameCount= min(frameCount, framesAvail);
      /*PRINTF(("<%d", frameCount * in->hw.bpf));*/
      return in->read(in,
		      pointerForOop(buf) + startSliceIndex * 2,
		      frameCount)
	* in->sq.channels;
    }
  return 0;
}


/*** mixer ***/


/* NOTES:
 * 
 *   - output volume is connected to PCM unless there is no such
 *     device, in which case we try master VOLUME instead.
 * 
 *   - input volume is connected to RECLEVEL unless there is no such
 *     device, in which case we try IGAIN instead.
 */

#define	LEVEL_MAX	100

struct mixer
{
  char	*path;
  int	 fd;
  int	 devices;	/* available mixer devices */
};

struct mixer dev_mixer= { "/dev/mixer", -1 };

struct mixer *mixer= 0;


static struct mixer *mixerOpen(struct mixer *mix)
{
  assert(mix);
  assert(mix->fd == -1);

  if ((mix->fd= open(mix->path, O_RDWR, 0)) < 0)
    {
      fprintf(stderr, "sound: ");
      perror(mix->path);
      return 0;
    }
  PRINTF(("sound: %s: opened with mode %d\n", mix->path, O_RDWR));

  /* read available devices */
  {
    if (IOCTL(mix->fd, SOUND_MIXER_READ_DEVMASK, &mix->devices))
      mix->devices= 0;
#  ifdef DEBUG
    printf("sound: %s: available devices:", mix->path);
    {
      int i= 0;
      for (i= 0; i < SOUND_MIXER_NRDEVICES; ++i)
	if (mix->devices & (1 << i))
	  printf(" %s", devName(i));
    }
    printf("\n");
#  endif
  }

  return mix;
}


static int mixerGetLevel(struct mixer *mix, int device, int *left, int *right)
{
  assert(mix);
  assert(mix->fd >= 0);

  if (mix->devices & (1 << device))
    {
      int vol= 0;
      if (IOCTL(mix->fd, MIXER_READ(device), &vol) >= 0)
	{
	  *left=  (vol >> 8) & 0xff;
	  *right= (vol     ) & 0xff;
	  return 1;
	}
    }
  return 0;
}


static int mixerSetLevel(struct mixer *mix, int device, int left, int right)
{
  assert(mix);
  assert(mix->fd >= 0);
  assert((left  >= 0) && (left  <= LEVEL_MAX));
  assert((right >= 0) && (right <= LEVEL_MAX));

  if (mix->devices & (1 << device))
    {
      int vol= (left << 8) | right;
      if (IOCTL(mix->fd, MIXER_WRITE(device), &vol) >= 0)
	{
	  PRINTF(("sound: %s: %s: level set to %d%% + %d%%\n", mix->path,
		  devName(device), left, right));
	  return 1;
	}
    }
  PRINTF(("sound: %s: %s: device not available\n", mix->path, devName(device)));
  return 0;
}



static void sound_Volume(double *left, double *right)
{
  if (mixer || (mixer= mixerOpen(&dev_mixer)))
    {
      int l= 0, r= 0;
      if ((  mixerGetLevel(mixer, SOUND_MIXER_PCM,     &l, &r))
	  || mixerGetLevel(mixer, SOUND_MIXER_VOLUME,  &l, &r))
	{
	  *left=  (double)l / (double)LEVEL_MAX;
	  *right= (double)r / (double)LEVEL_MAX;
	  return;
	}
    }
  success(false);
}


/* NOTE: I have a fundamental objection to the existence of this
 * primitive (and snd_SetRecLevel).  Unix audio philosophy is that
 * sound input/output and mixer control are totally seperate
 * activities.  Choice of input source, output destination and device
 * levels should always be left to an external mixer program.  The
 * option `-nommixer' therefore disables all writing to the mixer
 * device for those of us who object to Squeak abritrarily resetting
 * our carefully-adjusted input levels whenever sound recording is
 * started.
 */
static void sound_SetVolume(double left, double right)
{
  if (noSoundMixer) return;
  if (mixer || (mixer= mixerOpen(&dev_mixer)))
    {
      int l= (int)(left  * (double)LEVEL_MAX);
      int r= (int)(right * (double)LEVEL_MAX);
      if (l < 0) l= 0; if (l > LEVEL_MAX) l= LEVEL_MAX;
      if (r < 0) r= 0; if (r > LEVEL_MAX) r= LEVEL_MAX;
      if ((  mixerSetLevel(mixer, SOUND_MIXER_PCM,    l, r))
	  || mixerSetLevel(mixer, SOUND_MIXER_VOLUME, l, r))
	return;
    }
  success(false);
}


#if 0
static int sound_RecordLevel(int *level)
{
  if (mixer || (mixer= mixerOpen(&dev_mixer)))
    {
      int l= 0, r= 0;
      if ((  mixerGetLevel(mixer, SOUND_MIXER_RECLEV, &l, &r))
	  || mixerGetLevel(mixer, SOUND_MIXER_IGAIN,  &l, &r))
	{
	  /* record level is average of l+r in the range 0..1000 */
	  *level= 1000 * (l + r) / 2 / 100;
	  return 1;
	}
    }
  return success(false);
}
#endif


static sqInt sound_SetRecordLevel(sqInt level)
{
  if (noSoundMixer) return 1;
  if (mixer || (mixer= mixerOpen(&dev_mixer)))
    {
      level= level * LEVEL_MAX / 1000;
      if (level < 0)
	level= 0;
      else if (level > 255)
	level= 255;

      if (mixerSetLevel(mixer, SOUND_MIXER_RECLEV, level, level)) return 1;
      if (mixerSetLevel(mixer, SOUND_MIXER_IGAIN,  level, level)) return 1;
    }
  return 0;
}

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

/*** debugging ***/


#ifdef DEBUG

static char *afmtName(int i)
{
  switch (i)
    {
    case AFMT_MU_LAW:	 return "MU_LAW";
    case AFMT_A_LAW:	 return "A_LAW";
    case AFMT_IMA_ADPCM: return "IMA_ADPCM";
    case AFMT_U8:	 return "U8";
    case AFMT_S16_LE:	 return "S16_LE";
    case AFMT_S16_BE:	 return "S16_BE";
    case AFMT_S8:	 return "S8";
    case AFMT_U16_LE:	 return "U16_LE";
    case AFMT_U16_BE:	 return "U16_BE";
    case AFMT_MPEG:	 return "MPEG";
    }
  return "*** UNKNOWN ***";
}

static char *capName(int i)
{
  switch (i)
    {
      case DSP_CAP_DUPLEX:   return "DUPLEX";
      case DSP_CAP_REALTIME: return "REALTIME";
      case DSP_CAP_BATCH:    return "BATCH";
      case DSP_CAP_COPROC:   return "COPROC";
      case DSP_CAP_TRIGGER:  return "TRIGGER";
      case DSP_CAP_MMAP:     return "MMAP";
    }
  return "*** UNKNOWN ***";
}

static char *devName(int dev)
{
  static char *names[]= SOUND_DEVICE_NAMES;
  if ((dev >= 0) && (dev <SOUND_MIXER_NRDEVICES)) return names[dev];
  return "*** ILLEGAL ***";
}

static char *rdName(reader rd)
{
  if (rd == input)   return "none";
  if (rd == rdMM__U) return "MM__U";
  if (rd == rdMM_E_) return "MM_E_";
  if (rd == rdMM_EU) return "MM_EU";
  if (rd == rdMM8__) return "MM8__";
  if (rd == rdMM8_U) return "MM8_U";
  if (rd == rdMS___) return "MS___";
  if (rd == rdMS__U) return "MS__U";
  if (rd == rdMS_E_) return "MS_E_";
  if (rd == rdMS_EU) return "MS_EU";
  if (rd == rdMS8__) return "MS8__";
  if (rd == rdMS8_U) return "MS8_U";
  if (rd == rdSM___) return "SM___";
  if (rd == rdSM__U) return "SM__U";
  if (rd == rdSM_E_) return "SM_E_";
  if (rd == rdSM_EU) return "SM_EU";
  if (rd == rdSM8__) return "SM8__";
  if (rd == rdSM8_U) return "SM8_U";
  if (rd == rdSS__U) return "SS__U";
  if (rd == rdSS_E_) return "SS_E_";
  if (rd == rdSS_EU) return "SS_EU";
  if (rd == rdSS8__) return "SS8__";
  if (rd == rdSS8_U) return "SS8_U";
  if (rd == 0)       return "*** NULL ***";
  return "*** ILLEGAL ***";
}

static char *wrName(writer wr)
{
  if (wr == output)  return "none";
  if (wr == wrMM__U) return "MM__U";
  if (wr == wrMM_E_) return "MM_E_";
  if (wr == wrMM_EU) return "MM_EU";
  if (wr == wrMM8__) return "MM8__";
  if (wr == wrMM8_U) return "MM8_U";
  if (wr == wrMS___) return "MS___";
  if (wr == wrMS__U) return "MS__U";
  if (wr == wrMS_E_) return "MS_E_";
  if (wr == wrMS_EU) return "MS_EU";
  if (wr == wrMS8__) return "MS8__";
  if (wr == wrMS8_U) return "MS8_U";
  if (wr == wrSM___) return "SM___";
  if (wr == wrSM__U) return "SM__U";
  if (wr == wrSM_E_) return "SM_E_";
  if (wr == wrSM_EU) return "SM_EU";
  if (wr == wrSM8__) return "SM8__";
  if (wr == wrSM8_U) return "SM8_U";
  if (wr == wrSS__U) return "SS__U";
  if (wr == wrSS_E_) return "SS_E_";
  if (wr == wrSS_EU) return "SS_EU";
  if (wr == wrSS8__) return "SS8__";
  if (wr == wrSS8_U) return "SS8_U";
  if (wr == 0)       return "*** NULL ***";
  return "*** ILLEGAL ***";
}

#endif /* DEBUG */


#include "SqSound.h"

SqSoundDefine(OSS);


#include "SqModule.h"

static void  sound_parseEnvironment(void)
{
  if (getenv("SQUEAK_NOMIXER")) noSoundMixer= 1;
}

static int   sound_parseArgument(int argc, char **argv)
{
  if (!strcmp(argv[0], "-nomixer")) return noSoundMixer= 1;
  return 0;
}

static void  sound_printUsage(void)
{
  printf("\nOSS <option>s:\n");
  printf("  -nomixer              disable mixer (volume) adjustment\n");
}

static void  sound_printUsageNotes(void)
{
}

static void *sound_makeInterface(void)
{
  return &sound_OSS_itf;
}

SqModuleDefine(sound, OSS);
