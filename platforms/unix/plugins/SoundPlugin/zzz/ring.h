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
//   Permission is hereby granted, free of charge, to any person obtaining a
//   copy of this software and associated documentation files (the "Software"),
//   to deal in the Software without restriction, including without limitation
//   the rights to use, copy, modify, merge, publish, distribute, sublicense,
//   and/or sell copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following conditions:
// 
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
// 
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//   DEALINGS IN THE SOFTWARE.


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
