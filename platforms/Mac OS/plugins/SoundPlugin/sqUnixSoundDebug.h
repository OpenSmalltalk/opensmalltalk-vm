#if 0

# define startSpy();
# define stopSpy();

#else

#define RED	0xff0000
#define GREEN	0x00ff00
#define BLUE	0x0000ff
#define WHITE	0xffffff
#define BLACK	0x000000

#include <pthread.h>

void rect(int h, int c, float l, float r);

void rect(int h, int c, float l, float r)
{
  extern long *dpyPixels;
  extern int   dpyPitch;
  int left= 250, width= 100, height= 2;
  long *base=  dpyPixels;
  int   pitch= dpyPitch / sizeof(long);
  int x, y;

  //printf("rect %d %d %g %g\n", h, c, l, r);
  assert(l >= 0.0);  assert(r >= 0.0);
  assert(l <= 1.0);  assert(r <= 1.0);

  base+= (int)left;
  base+= (int)(h * height * pitch);

  for (y= 0; y < height; ++y)
    {
      for (x= (int)(width * l); x < (int)(width * r); ++x)
	((long *)base)[x]= c;
      base+= pitch;
    }
}

void fill(int h, int c, float l, float r);
void fill(int h, int c, float l, float r)
{
  if (r > 1.0)
    {
      rect(h, c, l, 1.0);
      rect(h, c, 0.0, r - 1.0);
    }
  else
    rect(h, c, l, r);
}


#if (USE_FIFO)

void update(void)
{
  if (output)
    {
      Buffer *b=   output->buffer;
      static int phase= 0;
      float size=  b->size;
      float out=   b->optr / size;
      float avail= b->avail / size;
      extern long *dpyPixels;

      fill(0,BLACK, 0.0, out);
      fill(0,GREEN, out, out+avail);
      if (out + avail < 1.0)
	fill(0,BLACK, out+avail, 1.0);
      fill(2,GREEN, 0.0, avail);
      fill(2,BLACK, avail, 1.0);

      phase= 1 - phase;
      feedback(10, phase * WHITE);

      memcpy(dpyPixels + 400, output->buffer->data, 400);
    }
}

#else

void update(void);
void update(void)
{
}

#endif


static int       running= 0;
static pthread_t spyThread;

static void *spy(void *ignored)
{
#pragma unused(ignored)
  struct sched_param params;
  int                policy;
  if (pthread_getschedparam(pthread_self(), &policy, &params))
    perror("getschedparam");
  params.sched_priority+= 9;
  if (pthread_setschedparam(pthread_self(), SCHED_RR, &params))
    perror("setschedparam");
  for (;;)
    {
      update();
      usleep(10000);
    }
}

void startSpy(void);
void startSpy(void)
{
  if (!pthread_create(&spyThread, 0, spy, 0))
    running= 1;
  else
    perror("pthread_create(spy)");
}

void stopSpy(void);
void stopSpy(void)
{
  if (running)
    {
      if (!pthread_cancel(spyThread))
	running= 0;
      else
	perror("pthread_cancel(spy)");
      running= 0;
    }
}


#endif // (DEBUG)
