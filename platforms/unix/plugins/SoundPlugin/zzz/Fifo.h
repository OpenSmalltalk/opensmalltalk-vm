#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


// NOTE: requires the client to define min and max on ints


typedef struct
{
  char *data;
  int   size;
  int   avail;
  int   iptr;
  int   optr;
} Buffer;


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

void Buffer_delete(Buffer *b)
{
  assert(b && b->data);
  free(b->data);
  free(b);
}


inline int Buffer_avail(Buffer *b)
{
  assert(!(b->avail & 3));
  return b->avail;
}

inline int Buffer_free(Buffer *b)
{
  return b->size - Buffer_avail(b);
}


inline void Buffer_getOutputPointers(Buffer *b, char **p1, int *n1, char **p2, int *n2)
{
  int optr=     b->optr;
  int avail=    Buffer_avail(b);
  int headroom= b->size - optr;
  if (avail == 0)
    {
      *p1=			*p2= 0;
      *n1=			*n2= 0;
    }
  else if (avail <= headroom)
    {
      *p1= b->data + optr;	*p2= 0;
      *n1= avail;		*n2= 0;
    }
  else
    {
      *p1= b->data + optr;	*p2= b->data;
      *n1= headroom;		*n2= avail - headroom;
    }
  assert(!(*n1 & 3));
  assert(!(*n2 & 3));
}

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

inline int Buffer_getInputPointer(Buffer *b, char **ptr)
{
  int iptr=     b->iptr;
  int free=     Buffer_free(b);
  int headroom= b->size - iptr;
  if (headroom < free) free= headroom;
  assert((iptr + free) <= b->size);
  *ptr= b->data + iptr;
  return free;
}


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

inline void Buffer_advanceInputPointer(Buffer *b, int size)
{
  int iptr= b->iptr;
  assert(!(size & 3));
  {
    int free= Buffer_free(b);
    free-= size;
    assert(free >= 0);
  }
  iptr += size;
  assert(iptr <= b->size);
  if (iptr == b->size) iptr= 0;
  b->iptr= iptr;
  b->avail += size;
}


inline void Buffer_prefill(Buffer *b, int bytes)
{
  char *ptr;
  int   size= Buffer_getInputPointer(b, &ptr);
  assert(!(bytes & 3));
  assert(bytes <= size);
  memset(ptr, 0, size);
  Buffer_advanceInputPointer(b, bytes);
}


inline int Buffer_write(Buffer *b, char *buf, int nbytes)
{
  int iptr= b->iptr;
  int bytesToCopy= min(nbytes, Buffer_free(b));
  int headroom= b->size - iptr;
  int bytesCopied= 0;

  assert(!(nbytes & 3));

  if (bytesToCopy >= headroom)
    {
      memcpy(b->data + iptr, buf, headroom);
      iptr= 0;
      bytesToCopy -= headroom;
      bytesCopied += headroom;
      if (bytesToCopy)
	{
	  memcpy(b->data, buf + bytesCopied, bytesToCopy);
	  iptr= bytesToCopy;
	  bytesCopied += bytesToCopy;
	}
    }
  else
    {
      memcpy(b->data + iptr, buf, bytesToCopy);
      iptr += bytesToCopy;
      bytesCopied= bytesToCopy;
    }
  b->iptr= iptr;
  b->avail += bytesCopied;
  return bytesCopied;
}


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


