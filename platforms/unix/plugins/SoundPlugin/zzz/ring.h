// ring.h -- lightweight ring buffers for sound i/o
// 
// Author: Ian.Piumarta@INRIA.Fr
// 
// Last edited: 
// 
//   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
//                              listed elsewhere in this file.
//   All rights reserved.
//   
//   This file is part of Unix Squeak.
// 
//      You are NOT ALLOWED to distribute modified versions of this file
//      under its original name.  If you modify this file then you MUST
//      rename it before making your modifications available publicly.
// 
//   This file is distributed in the hope that it will be useful, but WITHOUT
//   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//   FITNESS FOR A PARTICULAR PURPOSE.
//   
//   You may use and/or distribute this file ONLY as part of Squeak, under
//   the terms of the Squeak License as described in `LICENSE' in the base of
//   this distribution, subject to the following additional restrictions:
// 
//   1. The origin of this software must not be misrepresented; you must not
//      claim that you wrote the original software.  If you use this software
//      in a product, an acknowledgment to the original author(s) (and any
//      other contributors mentioned herein) in the product documentation
//      would be appreciated but is not required.
// 
//   2. You must not distribute (or make publicly available by any
//      means) a modified copy of this file unless you first rename it.
// 
//   3. This notice must not be removed or altered in any source distribution.
// 
//   Using (or modifying this file for use) in any context other than Squeak
//   changes these copyright conditions.  Read the file `COPYING' in the
//   directory `platforms/unix/doc' before proceeding with any such use.


typedef struct _ring
{
  char **bufs;
  int    bufCount;
  int	 bufSize;
  int	 iBuf;
  int	 oBuf;
  int	 nBufs;
} ring;


static ring *ring_new(int bufCount, int bufSize)
{
  ring *r= (ring *)malloc(sizeof(ring));

  if (r)
    {
      if ((r->bufs= (char **)malloc(bufCount * sizeof(char *))))
	{
	  // Would there be any advantage to allocating wired memory
	  // via mmap() and mlock()?
	  int i;
	  for (i= 0;  i < bufCount;  ++i)
	    if (!(r->bufs[i]= (char *)malloc(bufSize)))
	      goto fail;
	  r->bufCount = bufCount;
	  r->bufSize  = bufSize;
	  r->iBuf     = 0;
	  r->oBuf     = 0;
	  r->nBufs    = 0;
	  return r;

	fail:
	  printf("sound: could not allocate ring buffer memory\n");
	  while (i--)
	    free(r->bufs[i]);
	  free(r->bufs);
	}
      free(r);
    }

  return 0;
}


static void ring_delete(ring *r)
{
  int i;
  assert(r);
  assert(r->bufs);
  for (i= 0;  i < r->bufCount;  ++i)
    {
      assert(r->bufs[i]);
      free(r->bufs[i]);
    }
  free(r->bufs);
  free(r);
}


// counting the number of filled buffers saves an awful lot of tedious
// logic involving the front and back pointers, which in turn saves an
// awful lot of tedious locking of mutexes.  the incr/decrs are
// effectively atomic and races will always fail conservatively (no
// data for input when 1 buffer has just been filled by the ioproc, no
// space for output when 1 buffer was just emptied by the ioproc) and
// cause an immediate retry (since the reader/writer is always the
// image -- the ioproc chugs along happily irrespective of the
// apparent buffer state).

static inline int ring_isEmpty(ring *r)	   { return r->nBufs == 0; }
static inline int ring_freeBufs(ring *r)   { return r->bufCount - r->nBufs; }
static inline int ring_availBufs(ring *r)  { return r->nBufs; }
static inline int ring_freeBytes(ring *r)  { return ring_freeBufs(r) * r->bufSize; }
static inline int ring_availBytes(ring *r) { return ring_availBufs(r) * r->bufSize; }

static inline void ring_oAdvance(ring *r)
{
  assert(r->nBufs > 0);
  r->oBuf= (r->oBuf + 1) % r->bufCount;
  r->nBufs--;
}

static inline void ring_iAdvance(ring *r)
{
  assert(r->nBufs < r->bufCount);
  r->iBuf= (r->iBuf + 1) % r->bufCount;
  r->nBufs++;
}

static inline char *ring_inputPointer(ring *r)
{
  return r->bufs[r->iBuf];
}

#if 0
static int ring_copyIn(ring *r, char *bytes, int size)
{
  int   freeBufs= ring_freeBufs(r);
  char *in= bytes;

  while (freeBufs-- && (size >= r->bufSize))
    {
      memcpy(r->bufs[r->iBuf], bytes, r->bufSize);
      in   += r->bufSize;
      size -= r->bufSize;
      ring_iAdvance(r);
    }
  return in - bytes;
}
#endif

static int ring_copyOut(ring *r, char *bytes, int size)
{
  int   availBufs= ring_availBufs(r);
  char *out= bytes;

  while (availBufs-- && (size >= r->bufSize))
    {
      memcpy(out, r->bufs[r->oBuf], r->bufSize);
      out  += r->bufSize;
      size -= r->bufSize;
      ring_oAdvance(r);
    }
  return out - bytes;
}
