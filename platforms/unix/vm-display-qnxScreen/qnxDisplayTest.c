/* qnxDisplayTest.c -- test basic rendering */

/* $QNX_CC $QNX_CFLAGS -trigraphs $QNX_LDFLAGS -lscreen -o displayTest qnxDisplayTest.c */


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>  /* sleep() */
#include <errno.h>
#include <screen/screen.h>
#include <sys/keycodes.h>

/* Pixels are kept as 32 bits: uint32_t */
typedef uint32_t pixel_t;
#include "Balloon.h"  /* Squeak Balloon image */

/* Forward declarations */
static void showBalloons( void *bufPtr );
static void showBalloonAt(void *bufPtr, int left, int top);
static inline void putPixel(void *bufPtr, int x, int y, pixel_t pix);


screen_context_t screenContext = NULL;
screen_event_t   event;
screen_window_t  window;
screen_buffer_t	 buffer;
void* bufPointer; /* buffer pointer */
int   stride;     /* buffer stride (bytes per scan line) */
int   size[2];    /* {width,height} in pixels */
const int alwaysTrue = 1;


int main(void) {
  
  int sessionVisible = SCREEN_PROPERTY_VISIBLE; /* => active */
  int usage          = SCREEN_USAGE_NATIVE;
  int eventType	     = 0;

  if (screen_create_context(&screenContext,SCREEN_APPLICATION_CONTEXT) < 0) {
    printf("\nqnx screenTest: Event creation failure with errno %d\n", errno);
    return -1;
  }

  if (screen_create_event(&event) < 0) {
    printf("\nqnx screenTest: Event creation failure with errno %d\n", errno);
    return -1;
  }

  if (screen_create_window_type(&window,
				screenContext,
				(SCREEN_APPLICATION_WINDOW |SCREEN_ROOT_WINDOW)) < 0) {
    printf("\nqnx screenTest: Window creation failure with errno %d\n", errno);
    return -1;
  }

  if (screen_create_window_buffers(window, 1) < 0) {
    printf("\nqnx screenTest: Single buffer creation failure with errno %d\n", errno);
    return -1;
  } 

  /* Render Setup */
  screen_set_window_property_iv(window, SCREEN_PROPERTY_FORMAT,
			(const int[]){ SCREEN_FORMAT_RGBX8888 });
  screen_set_window_property_iv(window, SCREEN_PROPERTY_USAGE,
			(const int[]) { SCREEN_USAGE_WRITE | SCREEN_USAGE_NATIVE });
  screen_get_window_property_iv(window, SCREEN_PROPERTY_BUFFER_SIZE,size);
  screen_get_window_property_pv(window, SCREEN_PROPERTY_BUFFERS, (void **)&buffer);
  screen_get_buffer_property_pv(buffer, SCREEN_PROPERTY_POINTER, &bufPointer);
  screen_get_buffer_property_iv(buffer, SCREEN_PROPERTY_STRIDE,  &stride);

  screen_fill(screenContext,
	      buffer,				/* chartreuse2 */
	      (const int[]){ SCREEN_BLIT_COLOR, 0x0076EE00, SCREEN_BLIT_END });

  screen_set_window_property_iv(window, SCREEN_PROPERTY_VISIBLE, &alwaysTrue);

  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 1 );

  showBalloons(bufPointer);
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 10 ) ; /* let the user see it */
  
  printf("\nExiting Display Test\n\n");

  screen_destroy_window( window );
  screen_destroy_context( screenContext );
   
  return 0;
}


static void showBalloons( void *bufPtr ) {
  int x, y;

  x = size[0] / 2;
  y = size[1] / 2;
  showBalloonAt(bufPtr,x,y) ;
  showBalloonAt(bufPtr,x+(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x+(x/2),y+(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y+(y/2)) ;
}
  

static void showBalloonAt(void *bufPtr, int left, int top)
{
  int x, y;
  char *data = balloon_data, pixel[4];
  pixel_t myPixel;
  int balloon_bytes_per_pixel = 4; /* 32 bits */

  /* Center Balloon on x,y point */
  left -= balloon_width_pixels  / 2;
  top  -= balloon_height_pixels / 2;
  for (y = 0; y < balloon_height_pixels; y++) {
    for (x = 0; x < balloon_width_pixels; x++) {
      /* extract RGB values from Balloon data */
      BALLOON_PIXEL( data, pixel );
      /* above side effect: data += balloon_bytes_per_pixel */
      putPixel(bufPtr,
	       left + x,
	       top + y,
	       ((pixel[0] << 16) | (pixel[1] << 8) | pixel[2])); /* RGB */
    }
  }
}

static inline void putPixel(void *bufPtr, int x, int y, pixel_t pix)
{
  if ((x >= 0) && (y >= 0) && (x < size[0]) && (y < size[1])) /* size[width,height] */
    {
      *((pixel_t *)(bufPtr
		    + (x  * 4) /* 4 = (32/8) = (bits-per-pixel/bits-per-byte)  */
		    + (y * stride)))
	= pix;
    }
}


/* --- E O F --- */
