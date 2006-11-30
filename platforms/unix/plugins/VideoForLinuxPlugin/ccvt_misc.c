/*  CCVT: ColourConVerT: simple library for converting colourspaces
    Copyright (C) 2002 Nemosoft Unv.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    For questions, remarks, patches, etc. for this program, the author can be
    reached at nemosoft@smcc.demon.nl.
*/

/* This file contains CCVT functions that aren't available in assembly yet
   (or are not worth programming)
 */

/* 
 * $Log: ccvt_misc.c,v $
 * Revision 1.7  2003/01/02 04:10:19  nemosoft
 * Adding ''upside down" conversion to rgb/bgr routines
 *
 * Revision 1.6  2002/12/03 23:29:11  nemosoft
 * *** empty log message ***
 *
 * Revision 1.5  2002/12/03 23:27:41  nemosoft
 * fixing log messages (gcc 3.2 complaining)
 *
   Revision 1.4  2002/12/03 22:29:07  nemosoft
   Fixing up FTP stuff and some video

   Revision 1.3  2002/11/03 22:46:25  nemosoft
   Adding various RGB to RGB functions.
   Adding proper copyright header too.
 */


#include "ccvt.h"
#include "ccvt_types.h"


/* YUYV: two Y's and one U/V */
void ccvt_yuyv_rgb32(int width, int height, const void *src, void *dst)
{


}


void ccvt_yuyv_bgr32(int width, int height, const void *src, void *dst)
{
   const unsigned char *s;
   PIXTYPE_bgr32 *d;
   int l, c;
   int r, g, b, cr, cg, cb, y1, y2;
   
   l = height;
   s = src;
   d = dst;
   while (l--) {
      c = width >> 2;
      while (c--) {
         y1 = *s++;
         cb = ((*s - 128) * 454) >> 8;
         cg = (*s++ - 128) * 88;
         y2 = *s++;
         cr = ((*s - 128) * 359) >> 8;
         cg = (cg + (*s++ - 128) * 183) >> 8;

         r = y1 + cr;
         b = y1 + cb;
         g = y1 - cg;
         SAT(r);
         SAT(g);
         SAT(b);               
         d->b = b;	
         d->g = g;           
         d->r = r;          
         d++;             
         r = y2 + cr;
         b = y2 + cb;
         g = y2 - cg;
         SAT(r);
         SAT(g);
         SAT(b);               
         d->b = b;
         d->g = g;           
         d->r = r;          
         d++;             
      }
   }
   
}

void ccvt_yuyv_420p(int width, int height, const void *src, void *dsty, void *dstu, void *dstv)
{
   int n, l, j;
   const unsigned char *s1, *s2;
   unsigned char *dy, *du, *dv;
   
   dy = (unsigned char *)dsty;
   du = (unsigned char *)dstu;
   dv = (unsigned char *)dstv;
   s1 = (unsigned char *)src;
   s2 = s1; // keep pointer
   n = width * height;
   for (; n > 0; n--) {
      *dy = *s1;
      dy++;
      s1 += 2;
   }
   
   /* Two options here: average U/V values, or skip every second row */
   s1 = s2; // restore pointer
   s1++; // point to U
   for (l = 0; l < height; l += 2) {
      s2 = s1 + width * 2; // odd line
      for (j = 0; j < width; j += 2) {
         *du = (*s1 + *s2) / 2;
         du++;
         s1 += 2;
         s2 += 2;
         *dv = (*s1 + *s2) / 2;
         dv++;
         s1 += 2;
         s2 += 2;
      }
      s1 = s2;
   }
}

/* RGB/BGR to RGB/BGR */

#define RGBBGR_BODY24(TIN, TOUT) \
void ccvt_ ## TIN ## _ ## TOUT (int width, int height, const void *const src, void *const dst) \
{ \
   const PIXTYPE_ ## TIN *in = src; \
   PIXTYPE_ ## TOUT *out = dst; \
   int l, c, stride = 0; \
   \
   if (height < 0) { stride = width; height = -height; } \
   out += ((height - 1) * width); \
   stride *= 2; \
   for (l = 0; l < height; l++) { \
      for (c = 0; c < width; c++) { \
         out->r = in->r; \
         out->g = in->g; \
         out->b = in->b; \
         in++; \
         out++; \
      } \
      out -= stride; \
   } \
}

#define RGBBGR_BODY32(TIN, TOUT) \
void ccvt_ ## TIN ## _ ## TOUT (int width, int height, const void *const src, void *const dst) \
{ \
   const PIXTYPE_ ## TIN *in = src; \
   PIXTYPE_ ## TOUT *out = dst; \
   int l, c, stride = 0; \
   \
   if (height < 0) { stride = width; height = -height; } \
   out += ((height - 1) * width); \
   stride *= 2; \
   for (l = 0; l < height; l++) { \
      for (c = 0; c < width; c++) { \
         out->r = in->r; \
         out->g = in->g; \
         out->b = in->b; \
         out->z = 0; \
         in++; \
         out++; \
      } \
      out -= stride; \
   } \
}

RGBBGR_BODY32(bgr24, bgr32)
RGBBGR_BODY32(bgr24, rgb32)
RGBBGR_BODY32(rgb24, bgr32)
RGBBGR_BODY32(rgb24, rgb32)

RGBBGR_BODY24(bgr32, bgr24)
RGBBGR_BODY24(bgr32, rgb24)
RGBBGR_BODY24(rgb32, bgr24)
RGBBGR_BODY24(rgb32, rgb24)
