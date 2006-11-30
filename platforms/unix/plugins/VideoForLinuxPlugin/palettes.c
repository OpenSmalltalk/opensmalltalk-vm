#include "ccvt.h"

#include <stdio.h>


typedef void (*Converter)(int width, int height, const void *src, void *dst);
struct palette_info {
   int       id;
   char*     name;
   float     bytesPerPixel;
   Converter converterFunction;
   int       depth;
};

void BGR24ToRGB32(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   unsigned char* dest = (unsigned char*) voidDst;
   unsigned char* src  = (unsigned char*) voidSrc;

   unsigned char red, green, blue;

   for (i = 0; i < width * height; i++) {
      blue  = *src++;
      green = *src++;
      red   = *src++;

      *dest++ = red;
      *dest++ = green;
      *dest++ = blue;
      *dest++ = 255;
   }
}

void BGR24ToRGB24(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   unsigned char* dest = (unsigned char*) voidDst;
   unsigned char* src  = (unsigned char*) voidSrc;

   unsigned char red, green, blue;

   for (i = 0; i < width * height; i++) {
      blue  = *src++;
      green = *src++;
      red   = *src++;

      *dest++ = red;
      *dest++ = green;
      *dest++ = blue;
   }
}


static struct palette_info palette_info_list[] = {
   { 0,  "UNKOWN - Unkown palette",                        0.0,                0,  0},
   { 1,  "GREY - Linear greyscale",                        0.0,                0,  8},
   { 2,  "HI240 - High 240 cube (BT848)",                  0.0,                0,  8},
   { 3,  "RGB565 - 565 16 bit RGB",                        2.0,                0, 16},
   { 4,  "RGB24 - 24bit RGB",                              3.0,     BGR24ToRGB24, 24},
   { 5,  "RGB32 - 32bit RGB",                              4.0, ccvt_bgr32_rgb24, 32},
   { 6,  "RGB555 - 555 15bit RGB",                         0.0,                0, 16},
   { 7,  "YUV422 - YUV422 capture",                        1.5,                0, 16},
   { 8,  "YUYV",                                           0.0,                0, 16},
   { 9,  "UYVY - The great thing about standards is ...",  0.0,                0, 16},
   {10,  "YUV420",                                         1.5,  ccvt_420p_rgb24, 16},
   {11,  "YUV411 - YUV411 capture",                        0.0,                0, 16},
   {12,  "RAW - RAW capture (BT848)",                      0.0,                0,  8},
   {13,  "YUV422P - YUV 4:2:2 Planar",                     0.0,                0, 16},
   {14,  "YUV411P - YUV 4:1:1 Planar",                     0.0,                0, 12},
   {15,  "YUV420P - YUV 4:2:0 Planar",                     1.5,  ccvt_420p_rgb24, 12},
   {16,  "YUV410P - YUV 4:1:0 Planar",                     0.0,                0,  9}
};


float paletteBytesPerPixel(int palette) {
   float bytesPerPixel;
   if (palette < 1 || palette > 16) {
      fprintf(stderr, "* Invalid palette=%d\n", palette);
      return 0;
   }

   bytesPerPixel = palette_info_list[palette].bytesPerPixel;
   if (bytesPerPixel == 0) {
      fprintf(stderr, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   return bytesPerPixel;
}


char* paletteName(int palette) {
   if (palette == 0) {
      return "*automatic*";
   }
   if (palette < 0 || palette > 16) {
      return "*UNKOWN*";
   }
   
   return palette_info_list[palette].name;
}


int paletteConvert(int palette,
		   int width, int height,
		   const void *src, void *dst) {
   Converter function;

   if (palette < 1 || palette > 16) {
      fprintf(stderr, "* Invalid palette=%d\n", palette);
      return 0;
   }

   function = palette_info_list[palette].converterFunction;
   if (function == 0) {
      fprintf(stderr, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   function(width, height, src, dst);

   return 1;
}




int paletteDepth(int palette) {
   int depth;
   if (palette < 1 || palette > 16) {
      fprintf(stderr, "* Invalid palette=%d\n", palette);
      return 0;
   }

   depth = palette_info_list[palette].depth;
   if (depth == 0) {
      fprintf(stderr, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   return depth;
}
