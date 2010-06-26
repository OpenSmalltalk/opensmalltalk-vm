/* sqUnixFBDevFramebuffer.c -- abstraction over the framebuffer device
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-10-31 13:32:59 by piumarta on emilia.inria.fr
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
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
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */


#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <linux/fb.h>
#include <linux/vt.h>
#include <linux/kd.h>


#define _self	struct fb *self


struct fb;

typedef void		(*fb_copyBits_t )(_self, char *bits, int l, int r, int t, int b);
typedef void		(*fb_drawPixel_t)(_self, int x, int y, int r, int g, int b);
typedef unsigned long	(*fb_getPixel_t )(_self, int x, int y);
typedef void		(*fb_putPixel_t )(_self, int x, int y, unsigned long pixel);

struct fb
{
  char				 *fbName;
  int				  fd;
  struct kb			 *kb;
  long int			  size;
  char				 *addr;
  struct fb_var_screeninfo	  var;
  struct fb_fix_screeninfo	  fix;
  long int			  pitch;
  int				  bpp;
  fb_copyBits_t			  copyBits;
  fb_drawPixel_t		  drawPixel;
  fb_getPixel_t			  getPixel;
  fb_putPixel_t			  putPixel;
  unsigned long			  whitePixel;
  unsigned long			  blackPixel;
  SqPoint			  cursorPosition;
  SqPoint			  cursorOffset;
  int				  cursorVisible;
  unsigned short		  cursorBits[16];
  unsigned short		  cursorMask[16];
  unsigned long			  cursorBack[16][16];
};


#define swab32(X)     ({ __u32 __x= (X);						\
                         ((__u32)((((__u32)(__x) & (__u32)0x000000ffUL) << 24)		\
				| (((__u32)(__x) & (__u32)0x0000ff00UL) <<  8)		\
				| (((__u32)(__x) & (__u32)0x00ff0000UL) >>  8)		\
				| (((__u32)(__x) & (__u32)0xff000000UL) >> 24) )); })


static char *visualName(_self)
{
  switch (self->fix.visual)
    {
    case FB_VISUAL_MONO01:		return "MONO01";
    case FB_VISUAL_MONO10:		return "MONO10";
    case FB_VISUAL_TRUECOLOR:		return "TRUECOLOR";
    case FB_VISUAL_PSEUDOCOLOR:		return "PSEUDOCOLOR";
    case FB_VISUAL_DIRECTCOLOR:		return "DIRECTCOLOR";
    case FB_VISUAL_STATIC_PSEUDOCOLOR:	return "STATIC_PSEUDOCOLOR";
    }
  return "UNKNOWN";
}


static inline int fb_width(_self)	{ return self->var.xres; }
static inline int fb_pitch(_self)	{ return self->pitch; }
static inline int fb_height(_self)	{ return self->var.yres; }
static inline int fb_depth(_self)	{ return self->var.bits_per_pixel; }


static inline unsigned long fb_getPixel_32(_self, int x, int y)
{
  return ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    ? *((unsigned long *)(self->addr
			   + (x + self->var.xoffset) * (32 / 8)
			   + (y + self->var.yoffset) * (self->fix.line_length)))
    : 0;
}

static inline void fb_putPixel_32(_self, int x, int y, unsigned long pix)
{
  if ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    {
      *((unsigned long *)(self->addr
			  + (x + self->var.xoffset) * (32 / 8)
			  + (y + self->var.yoffset) * (self->fix.line_length)))
	= pix;
    }
}


static inline unsigned long fb_getPixel_16(_self, int x, int y)
{
  return ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    ? *((unsigned short *)(self->addr
			   + (x + self->var.xoffset) * (16 / 8)
			   + (y + self->var.yoffset) * (self->fix.line_length)))
    : 0;
}

static inline void fb_putPixel_16(_self, int x, int y, unsigned long pix)
{
  if ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    {
      *((unsigned short *)(self->addr
			   + (x + self->var.xoffset) * (16 / 8)
			   + (y + self->var.yoffset) * (self->fix.line_length)))
	= pix;
    }
}


static inline unsigned long fb_getPixel_8(_self, int x, int y)
{
  return ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    ? *((unsigned char *)(self->addr
			  + (x + self->var.xoffset)
			  + (y + self->var.yoffset) * (self->fix.line_length)))
    : 0;
}


static inline void fb_putPixel_8(_self, int x, int y, unsigned long pix)
{
  if ((x >= 0) && (y >= 0) && (x < fb_width(self)) && (y < fb_height(self)))
    {
      *((unsigned char *)(self->addr
			  + (x + self->var.xoffset)
			  + (y + self->var.yoffset) * (self->fix.line_length)))
	= pix;
    }
}


static void fb_drawPixel_rgb8888(_self, int x, int y, int r, int g, int b)
{
  fb_putPixel_32(self, x, y, (r << 16) | (g << 8) | (b << 0));
}

static void fb_drawPixel_rgb565(_self, int x, int y, int r, int g, int b)
{
  fb_putPixel_16(self, x, y, (((r >> 3) & 31) << 11) | (((g >> 2) & 63) <<  5) | (((b >> 3) & 31) <<  0));
}

static void fb_drawPixel_rgb555(_self, int x, int y, int r, int g, int b)
{
  fb_putPixel_16(self, x, y, (((r >> 3) & 31) << 10) | (((g >> 3) & 31) <<  5) | (((b >> 3) & 31) <<  0));
}

static void fb_drawPixel_rgb332(_self, int x, int y, int r, int g, int b)
{
  unsigned char t;
  if      ((r == 0)   && (g == 0)   && (b == 255)) t= 0;
  else if ((r == 255) && (g == 255) && (b == 255)) t= 1;
  else	  t= (40 + (r / 43) * 36 + (g / 43) * 6 + (b / 43) * 1);
  fb_putPixel_8(self, x, y, t);
}


static void hideCursor(_self)
{
  if (self->cursorVisible)
    {
      int xo= self->cursorPosition.x + self->cursorOffset.x;
      int yo= self->cursorPosition.y + self->cursorOffset.y;
      int x, y;
      for (y= 0;  y < 16;  ++y)
	for (x= 0;  x < 16;  ++x)
	  self->putPixel(self, xo + x, yo + y, self->cursorBack[y][x]);
      self->cursorVisible= 0;
    }
}


static void showCursor(_self)
{
  if (!self->cursorVisible)
    {
      int xo= self->cursorPosition.x + self->cursorOffset.x;
      int yo= self->cursorPosition.y + self->cursorOffset.y;
      int y;
      for (y= 0;  y < 16;  ++y)
	{
	  unsigned short bits= self->cursorBits[y];
	  unsigned short mask= self->cursorMask[y];
	  int x;
	  for (x= 0;  x < 16;  ++x)
	    {
	      self->cursorBack[y][x]= self->getPixel(self, xo + x, yo + y);
	      if      (bits & 0x8000) self->putPixel(self, xo + x, yo + y, self->blackPixel);
	      else if (mask & 0x8000) self->putPixel(self, xo + x, yo + y, self->whitePixel);
	      bits <<= 1;
	      mask <<= 1;
	    }
	}
      self->cursorVisible= 1;
    }
}


static int cursorIn(_self, int l, int r, int t, int b)
{
  int cl= self->cursorPosition.x + self->cursorOffset.x;
  int cr= cl + 15;
  int ct= self->cursorPosition.y + self->cursorOffset.y;
  int cb= ct + 15;
  return !((cr < l) || (cl > r) || (ct > b) || (cb < t));
}

static inline void hideCursorIn(_self, int l, int r, int t, int b)
{
  if (cursorIn(self, l, r, t, b))
    hideCursor(self);
}

static inline void showCursorIn(_self, int l, int r, int t, int b)
{
  if (cursorIn(self, l, r, t, b))
    showCursor(self);
}


static void fb_setCursor(_self, char *bits, char *mask, int xoff, int yoff)
{
  int y;
  hideCursor(self);
  self->cursorOffset.x= xoff;
  self->cursorOffset.y= yoff;
  for (y= 0;  y < 16;  ++y)
    {
      self->cursorBits[y]= (((unsigned long *)bits)[y]) >> 16;
      self->cursorMask[y]= (((unsigned long *)mask)[y]) >> 16;
    }
  showCursor(self);
}


static void fb_advanceCursor(_self, int dx, int dy)
{
  hideCursor(self);
  self->cursorPosition.x= max(0, min(self->cursorPosition.x + dx, fb_width(self) - 1));
  self->cursorPosition.y= max(0, min(self->cursorPosition.y + dy, fb_height(self) - 1));
  showCursor(self);
}


static void fb_copyBits_32(_self, char *bits, int l, int r, int t, int b)
{
  int x, y;
  hideCursorIn(self, l, r, t, b);
  for (y= t;  y < b;  ++y)
    {
      unsigned long *in= (unsigned long *)(bits + ((l + (y * fb_width(self))) * 4));
      unsigned long *out= (unsigned long *)(self->addr + ((l + (y * fb_pitch(self))) * 4));
      for (x= l;  x < r;  x += 1, in += 1, out += 1)
	{
	  out[0]= in[0];
	}
    }
  showCursorIn(self, l, r, t, b);
}


static inline unsigned short fb_repack565(unsigned short pixel)
{
  return ((pixel & 0x7c00) << 1)
    |    ((pixel & 0x03e0) << 1)
    |    ((pixel & 0x001f) << 0);
}


static void fb_copyBits_16(_self, char *bits, int l, int r, int t, int b)
{
  int x, y;
  l &= 0xfffe;
  hideCursorIn(self, l, r, t, b);
  for (y= t;  y < b;  ++y)
    {
      unsigned short *in= (unsigned short *)(bits + ((l + (y * fb_width(self))) * 2));
      unsigned short *out= (unsigned short *)(self->addr + ((l + (y * fb_pitch(self))) * 2));
      for (x= l;  x < r;  x += 2, in += 2, out += 2)
	{
#	 if defined(WORDS_BIGENDIAN)
	  out[0]= fb_repack565(in[0]);
	  out[1]= fb_repack565(in[1]);
#	 else
	  out[0]= fb_repack565(in[1]);
	  out[1]= fb_repack565(in[0]);
#	 endif
	}
    }
  showCursorIn(self, l, r, t, b);
}

static void fb_copyBits_15(_self, char *bits, int l, int r, int t, int b)
{
  int x, y;
  l &= 0xfffe;
  hideCursorIn(self, l, r, t, b);
  for (y= t;  y < b;  ++y)
    {
      unsigned short *in= (unsigned short *)(bits + ((l + (y * fb_width(self))) * 2));
      unsigned short *out= (unsigned short *)(self->addr + ((l + (y * fb_pitch(self))) * 2));
      for (x= l;  x < r;  x += 2, in += 2, out += 2)
	{
#	 if defined(WORDS_BIGENDIAN)
	  *(unsigned long *)out= *(unsigned long *)in;
#	 else
	  out[0]= in[1];
	  out[1]= in[0];
#	 endif
	}
    }
  showCursorIn(self, l, r, t, b);
}

static void fb_copyBits_8(_self, char *bits, int l, int r, int t, int b)
{
  int x, y;
  l &= 0xfffc;
  hideCursorIn(self, l, r, t, b);
  for (y= t;  y < b;  ++y)
    {
      unsigned char *in= (unsigned char *)(bits + ((l + (y * fb_pitch(self)))));
      unsigned char *out= (unsigned char *)(self->addr + ((l + (y * fb_pitch(self)))));
      for (x= l;  x < r;  x += 4, in += 4, out += 4)
	{
	  unsigned long pix= *(unsigned long *)out= *(unsigned long *)in;
#        if !defined(WORDS_BIGENDIAN)
	  pix= swab32(pix);
#        endif
	  *(unsigned long *)out= pix;
	}
    }
  showCursorIn(self, l, r, t, b);
}



static void fb_initPseudoColour(_self)
{
  struct fb_cmap cmap;
  unsigned short red, green, blue, transp;

  cmap.len   	= 1;
  cmap.red   	= &red;
  cmap.green 	= &green;
  cmap.blue  	= &blue;
  cmap.transp = &transp;
  transp = 0;

# define SetColour(I, R, G, B)								\
  {											\
    cmap.start= (I);									\
    red=   (R);										\
    green= (G);										\
    blue=  (B);										\
    if (-1 == ioctl(self->fd, FBIOPUTCMAP, (void *)&cmap)) fatalError("FBIOPUTCMAP");	\
  }

  /* 1-bit colours (monochrome) */
  SetColour(0, 65535, 65535, 65535);	/* white or transparent */
  SetColour(1,     0,     0,     0);	/* black */

  /* additional colours for 2-bit colour */
  SetColour(2, 65535, 65535, 65535);	/* opaque white */
  SetColour(3, 32768, 32768, 32768);	/* 1/2 gray */

  /* additional colours for 4-bit colour */
  SetColour( 4, 65535,     0,     0);	/* red */
  SetColour( 5,     0, 65535,     0);	/* green */
  SetColour( 6,     0,     0, 65535);	/* blue */
  SetColour( 7,     0, 65535, 65535);	/* cyan */
  SetColour( 8, 65535, 65535,     0);	/* yellow */
  SetColour( 9, 65535,     0, 65535);	/* magenta */
  SetColour(10,  8192,  8192,  8192);	/* 1/8 gray */
  SetColour(11, 16384, 16384, 16384);	/* 2/8 gray */
  SetColour(12, 24576, 24576, 24576);	/* 3/8 gray */
  SetColour(13, 40959, 40959, 40959);	/* 5/8 gray */
  SetColour(14, 49151, 49151, 49151);	/* 6/8 gray */
  SetColour(15, 57343, 57343, 57343);	/* 7/8 gray */

  /* additional colours for 8-bit colour */
  /* 24 more shades of gray (does not repeat 1/8th increments) */
  SetColour(16,  2048,  2048,  2048);	/*  1/32 gray */
  SetColour(17,  4096,  4096,  4096);	/*  2/32 gray */
  SetColour(18,  6144,  6144,  6144);	/*  3/32 gray */
  SetColour(19, 10240, 10240, 10240);	/*  5/32 gray */
  SetColour(20, 12288, 12288, 12288);	/*  6/32 gray */
  SetColour(21, 14336, 14336, 14336);	/*  7/32 gray */
  SetColour(22, 18432, 18432, 18432);	/*  9/32 gray */
  SetColour(23, 20480, 20480, 20480);	/* 10/32 gray */
  SetColour(24, 22528, 22528, 22528);	/* 11/32 gray */
  SetColour(25, 26624, 26624, 26624);	/* 13/32 gray */
  SetColour(26, 28672, 28672, 28672);	/* 14/32 gray */
  SetColour(27, 30720, 30720, 30720);	/* 15/32 gray */
  SetColour(28, 34815, 34815, 34815);	/* 17/32 gray */
  SetColour(29, 36863, 36863, 36863);	/* 18/32 gray */
  SetColour(30, 38911, 38911, 38911);	/* 19/32 gray */
  SetColour(31, 43007, 43007, 43007);	/* 21/32 gray */
  SetColour(32, 45055, 45055, 45055);	/* 22/32 gray */
  SetColour(33, 47103, 47103, 47103);	/* 23/32 gray */
  SetColour(34, 51199, 51199, 51199);	/* 25/32 gray */
  SetColour(35, 53247, 53247, 53247);	/* 26/32 gray */
  SetColour(36, 55295, 55295, 55295);	/* 27/32 gray */
  SetColour(37, 59391, 59391, 59391);	/* 29/32 gray */
  SetColour(38, 61439, 61439, 61439);	/* 30/32 gray */
  SetColour(39, 63487, 63487, 63487);	/* 31/32 gray */

  /* The remainder of colour table defines a colour cube with six steps
     for each primary colour.  Note that the corners of this cube repeat
     previous colours, but simplifies the mapping between RGB colours and
     colour map indices.  The colour cube spans indices 40 through 255.
  */
  {
    int r, g, b;
    for (r= 0; r < 6; r++)
      for (g= 0; g < 6; g++)
	for (b= 0; b < 6; b++)
	  SetColour(40 + ((36 * r) + (6 * b) + g), (r * 65535) / 5, (g * 65535) / 5, (b * 65535) / 5);
  }
# undef SetColour
}


static void fb_initDirectColour(_self)
{
  /* Create a linear ramp for each colour channel.  Channels can be up
     to 8 bits wide and of unequal widths.
  */
  int rpad= 16 - self->var.red  .length;
  int gpad= 16 - self->var.green.length;
  int bpad= 16 - self->var.blue .length;

  struct fb_cmap cmap;
  unsigned short red, green, blue, transp;
  unsigned int   i;

  cmap.len   	= 1;
  cmap.red   	= &red;
  cmap.green 	= &green;
  cmap.blue  	= &blue;
  cmap.transp = &transp;
  transp = 0;
  for (i= 0;  i < 256;  ++i)	/* wraps for channels < 8 bits */
    {
      cmap.start= i;
      red    = (i << rpad);
      green  = (i << gpad);
      blue   = (i << bpad);
      if (-1 == ioctl(self->fd, FBIOPUTCMAP, (void *)&cmap)) fatalError("FBIOPUTCMAP");
    }
}


static void fb_initVisual(_self)
{
  if (ioctl(self->fd, FBIOGET_FSCREENINFO, &self->fix))  fatalError("FBIOGET FSCREENINFO");
  if (ioctl(self->fd, FBIOGET_VSCREENINFO, &self->var))  fatalError("FBIOGET VSCREENINFO");

  self->var.xoffset=  0;
  self->var.yoffset=  0;
  self->var.activate= FB_ACTIVATE_NOW;
  ioctl(self->fd, FBIOPAN_DISPLAY, &self->var);

  self->size= fb_height(self) * self->fix.line_length;
  self->pitch= self->fix.line_length / self->var.bits_per_pixel * 8;

  DPRINTF("%s: %dx%dx%d+%x+%x (%dx%d) %s, rgb %d+%d %d+%d %d+%d pitch %d(%d)\n", self->fbName,
	  self->var.xres, self->var.yres, self->var.bits_per_pixel, self->var.xoffset, self->var.yoffset,
	  self->var.xres_virtual, self->var.yres_virtual,
	  visualName(self),
	  self->var.red  .offset, self->var.red  .length,
	  self->var.green.offset, self->var.green.length,
	  self->var.blue .offset, self->var.blue .length,
	  self->fix.line_length, self->pitch);

  if (self->var.bits_per_pixel == 8)
    self->bpp= 8;
  else
    self->bpp= self->var.red.length + self->var.green.length + self->var.blue.length;

  if ((24 == self->bpp) && (32 == self->var.bits_per_pixel))
    self->bpp= 32;

  switch (self->bpp)
    {
    case 32:
      self->copyBits=  	fb_copyBits_32;
      self->drawPixel= 	fb_drawPixel_rgb8888;
      self->getPixel=  	fb_getPixel_32;
      self->putPixel=  	fb_putPixel_32;
      self->whitePixel= 0xffffffff;
      self->blackPixel= 0x00000000;
      break;

    case 16:
      self->copyBits=  	fb_copyBits_16;
      self->drawPixel= 	fb_drawPixel_rgb565;
      self->getPixel=  	fb_getPixel_16;
      self->putPixel=  	fb_putPixel_16;
      self->whitePixel= 0xffff;
      self->blackPixel= 0x0000;
      break;

    case 15:
      self->copyBits=   fb_copyBits_15;
      self->drawPixel=  fb_drawPixel_rgb555;
      self->getPixel=  	fb_getPixel_16;
      self->putPixel=  	fb_putPixel_16;
      self->whitePixel= 0x7fff;
      self->blackPixel= 0x0000;
      break;

    case 8:
      self->copyBits=   fb_copyBits_8;
      self->drawPixel=  fb_drawPixel_rgb332;
      self->getPixel=  	fb_getPixel_8;
      self->putPixel=  	fb_putPixel_8;
      self->whitePixel= 0x00;
      self->blackPixel= 0x01;
      break;

    default:
      fprintf(stderr, "%s: %d bpp (%d+%d+%d) not supported\n", self->fbName, self->bpp,
	      self->var.red.length, self->var.green.length, self->var.blue.length);
      exit(1);
    }

  switch (self->fix.visual)
    {
    case FB_VISUAL_TRUECOLOR:	/* nothing to do */
      break;

    case FB_VISUAL_DIRECTCOLOR:
      if (self->bpp > 8)
	fb_initDirectColour(self);
      else
	{
	  fprintf(stderr, "%s: DIRECTCOLOR visual not supported at depth %d\n", self->fbName, self->bpp);
	  exit(1);
	}
      break;

    case FB_VISUAL_PSEUDOCOLOR:
      if (self->bpp == 8)
	fb_initPseudoColour(self);
      else
	{
	  fprintf(stderr, "%s: PSEUDOCOLOR visual not supported at depth %d\n", self->fbName, self->bpp);
	  exit(1);
	}
      break;

    default:
      fprintf(stderr, "%s: %s visual not supported\n", self->fbName, visualName(self));
      exit(1);
      break;
    }
}


static void fb_initBuffer(_self)
{
  assert(self->addr == 0);
  self->addr= (char *)mmap(0, self->size, PROT_READ | PROT_WRITE, MAP_SHARED, self->fd, 0);
  if (self->addr == (char *)MAP_FAILED) fatalError("mmap");
  DPRINTF("%s: mapped at %p + %ld\n", self->fbName, self->addr, self->size);
}


static void fb_freeBuffer(_self)
{
  if (self->addr)
    {
      munmap(self->addr, self->size);
      self->addr= 0;
      DPRINTF("%s: unmapped\n", self->fbName);
    }
}


static void fb_initGraphics(_self)
{
  int x, y;
  assert(self->kb);
  kb_initGraphics(self->kb);
  for (y= 0;  y < fb_height(self);  ++y)
    for (x= 0;  x < fb_width(self);  ++x)
      self->putPixel(self, x, y, self->whitePixel);
}


static void fb_freeGraphics(_self)
{
  if (self->putPixel)
    {
      int x, y;
      for (y= 0;  y < fb_height(self);  ++y)
	for (x= 0;  x < fb_width(self);  ++x)
	  self->putPixel(self, x, y, 0);
    }
  if (self->kb)
    kb_freeGraphics(self->kb);
}


static void fb_initCursor(_self)
{
  self->cursorPosition.x= fb_width(self) / 2;
  self->cursorPosition.y= fb_height(self) / 2;
}


static int fb_open(_self, struct kb *kb, char *fbDev)
{
  assert(self->fd == -1);
  if (fbDev)
    self->fd= open(self->fbName= fbDev, O_RDWR);
  else
    {
      char *fbs[]= { "/dev/fb", "/dev/fb0", "/dev/fb0current", 0 };
      int i;
      for (i= 0;  fbs[i];  ++i)
	if ((self->fd= open(self->fbName= fbs[i], O_RDWR)) >= 0)
	  break;
      else
	perror(fbs[i]);
    }
  if (self->fd < 0)
    failPermissions("framebuffer");

  self->kb= kb;

  DPRINTF("using: %s (%d)\n", self->fbName, self->fd);

  fb_initVisual(self);
  fb_initBuffer(self);
  fb_initGraphics(self);
  fb_initCursor(self);

  return 1;
}


static void fb_close(_self)
{
  fb_freeGraphics(self);
  fb_freeBuffer(self);
  if (self->fd >= 0)
    {
      close(self->fd);
      DPRINTF("%s (%d) closed\n", self->fbName, self->fd);
      self->fd= -1;
    }
  self->kb= 0;
}


static struct fb *fb_new(void)
{
  _self= (struct fb *)calloc(1, sizeof(struct fb));
  if (!self) outOfMemory();
  self->fd=  -1;
  return self;
}


static void fb_delete(_self)
{
  assert(self->addr ==  0);
  assert(self->fd   == -1);
  free(self);
}


#undef _self
