#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


enum {
  Buffer_Free,
  Buffer_Busy,
  Buffer_Full,
  Buffer_Done
};


typedef struct
{
  int	 state;
  int	 size;
  int	 iptr;
  int	 optr;	// 0 <= optr <= iptr <= size
  char	*data;
} Buffer;


Buffer *Buffer_new(int size)
{
  Buffer *b= (Buffer *)calloc(1, sizeof(Buffer));
  if (b)
    {
      b->state= Buffer_Free;
      b->size=  size;
      if ((b->data= (char *)calloc(1, size)))
	return b;
      free(b);
    }
  return 0;
}


void Buffer_delete(Buffer *b)
{
  assert(b && b->data);
  free(b->data);
  free(b);
}


void Buffer_reset(Buffer *b)
{
  b->state= Buffer_Free;
  b->iptr= b->optr= 0;
}


int Buffer_avail(Buffer *b)
{
  return b->iptr - b->optr;
}

int Buffer_free(Buffer *b)
{
  return b->size - b->iptr;
}


typedef struct
{
  Buffer *input;
  Buffer *output;
} DBuffer;


DBuffer *DBuffer_new(int size)
{
  DBuffer *d= (DBuffer *)calloc(1, sizeof(DBuffer));
  if (d)
    {
      if ((d->input= Buffer_new(size)))
	{
	  if ((d->output= Buffer_new(size)))
	    return d;
	  Buffer_delete(d->input);
	}
      free(d);
    }
  return 0;
}


void DBuffer_delete(DBuffer *d)
{
  assert(d && d->input && d->output);
  Buffer_delete(d->input);
  Buffer_delete(d->output);
  free(d);
}


int DBuffer_swap(DBuffer *d)
{
  if (d->input->state == Buffer_Full)
    {
      Buffer *i= d->output;
      Buffer *o= d->input;
      d->input=  i;
      d->output= o;
      Buffer_reset(i);
      return 1;
    }
  d->output->state= Buffer_done;
  return 0;
}
