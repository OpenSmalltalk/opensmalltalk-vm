#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


enum {
  Block_Free;
  Block_Busy;
  Block_Full;
  Block_Done;
};


typedef struct
{
  int	 state;
  int	 capacity;
  int	 size;
  char	*data;
} Block;


Block *Block_new(int size)
{
  size &= ~(4 * sizeof(double) - 1);
  Block *b= (Block *)calloc(1, sizeof(Block));
  if (b)
    {
      b->state= Block_Free;
      b->capacity= size;
      if ((b->data= (char *)calloc(1, size)))
	return b;
      free(b);
    }
  return 0;
}


void Block_delete(Block *b)
{
  free(b->data);
  free(b);
}


void Block_reset(Block *b)
{
  b->state= Block_Free;
  b->size=  0;
}


typedef struct
{
  Block *input;
  Block *output;
} Buffer;


Buffer *Buffer_new(int size)
{
  Buffer *b= (Buffer *)calloc(1, sizeof(Buffer));
  if (b)
    {
      if ((b->input= Block_new(size)))
	{
	  if ((b->output= Block_new(size)))
	    return b;
	  Buffer_delete(b->input);
	}
      free(b);
    }
  return 0;
}


void Buffer_delete(Buffer *b)
{
  Block_delete(b->input);
  Block_delete(b->output);
  delete(b);
}


int Buffer_swap(Buffer *b)
{
  if (input->state == Block_Full)
    {
      Block *b= input;
      Block_reset(b->output);
      b->input= b->output;
      b->output= b->input;
      return 1;
    }
  output->state= Block_done;
  return 0;
}
