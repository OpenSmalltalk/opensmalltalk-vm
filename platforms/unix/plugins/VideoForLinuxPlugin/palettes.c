#include "ccvt.h"

#include <stdio.h>
#include "palettes.h"


struct palette_info {
   int       id;
   char*     name;
   float     bytesPerPixel;
   Converter converterFunction24;
   Converter converterFunction16;
   int       depth;
};


inline void BGR24ToRGB32(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   unsigned char* dest = (unsigned char*) voidDst;
   unsigned char* src  = (unsigned char*) voidSrc;

   unsigned char red, green, blue;

   const unsigned int widthTimesHeight = width * height;
   for (i = 0; i < widthTimesHeight; i++) {
      blue  = *src++;
      green = *src++;
      red   = *src++;

      *dest++ = red;
      *dest++ = green;
      *dest++ = blue;
      *dest++ = 255;
   }
}

inline void RGB565ToRGB24(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   const unsigned char* src  = (unsigned char*) voidSrc;
         unsigned char* dest = (unsigned char*) voidDst;

   unsigned char b1, b2;

   unsigned char red, green, blue;

   const unsigned int widthTimesHeight = width * height;
   for (i = 0; i < widthTimesHeight; i++) {
      b2 = *src++;
      b1 = *src++;

      red   = b1 & 248 /* 11111000 */;
      green = (b1 << 5) | (b2 >> 5);
      blue  = b2 << 3;

      *dest++ = red;
      *dest++ = green;
      *dest++ = blue;
   }
}

inline void BGR24ToRGB24(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   unsigned char* dest = (unsigned char*) voidDst;
   unsigned char* src  = (unsigned char*) voidSrc;

   unsigned char red, green, blue;

   const unsigned int widthTimesHeight = width * height;
   for (i = 0; i < widthTimesHeight; i++) {
       blue  = *src++;
       green = *src++;
       red   = *src++;

       *dest++ = red;
       *dest++ = green;
       *dest++ = blue;
   }
}

inline unsigned char clip(const int pixel) {
    int result;

    result = ((pixel < 0) ? 0 : pixel);
    return (unsigned char) ((result < 255) ? result : 255);
}


// from: http://en.wikipedia.org/wiki/YUV422
inline void YUV444toRGB888(const unsigned char y,
			   const unsigned char u,
			   const unsigned char v,
			   unsigned char* dest) {
   const int C = y - 16;
   const int D = u - 128;
   const int E = v - 128;

   dest[0] = clip(( 298 * C           + 409 * E + 128) >> 8);
   dest[1] = clip(( 298 * C - 100 * D - 208 * E + 128) >> 8);
   dest[2] = clip(( 298 * C + 516 * D           + 128) >> 8);
}


// from: http://en.wikipedia.org/wiki/YUV422
inline void YUYVToRGB24(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   const unsigned char* src  = (unsigned char*) voidSrc;
         unsigned char* dest = (unsigned char*) voidDst;

   unsigned char u, y1, v, y2;

   const unsigned int widthTimesHeight = width * height;
   for (i = 0; i < widthTimesHeight; i += 2) {
      y1 = *src++;
      u  = *src++;
      y2 = *src++;
      v  = *src++;

      YUV444toRGB888(y1, u, v, dest);
      dest += 3;

      YUV444toRGB888(y2, u, v, dest);
      dest += 3;
   }
}

inline void YUV422ToRGB24(int width, int height, const void *voidSrc, void *voidDst) {
   int i;

   unsigned char* dest = (unsigned char*) voidDst;
   unsigned char* src  = (unsigned char*) voidSrc;

   unsigned char u, y1, v, y2;

   const unsigned int widthTimesHeight = width * height;
   for (i = 0; i < widthTimesHeight; i += 2) {
      u  = *src++;
      y1 = *src++;
      v  = *src++;
      y2 = *src++;

      YUV444toRGB888(y1, u, v, dest);
      dest += 3;

      YUV444toRGB888(y2, u, v, dest);
      dest += 3;
   }
}

static struct palette_info palette_info_list[] = {
   { 0,  "UNKOWN - Unkown palette",                        0.0,                0,                  0,  0},
   { 1,  "GREY - Linear greyscale",                        0.0,                0,                  0,  8},
   { 2,  "HI240 - High 240 cube (BT848)",                  0.0,                0,                  0,  8},
   { 3,  "RGB565 - 565 16 bit RGB",                        2.0,    RGB565ToRGB24,                  0, 16},
   { 4,  "RGB24 - 24bit RGB",                              3.0,     BGR24ToRGB24,                  0, 24},
   { 5,  "RGB32 - 32bit RGB",                              4.0, ccvt_bgr32_rgb24,                  0, 32},
   { 6,  "RGB555 - 555 15bit RGB",                         0.0,                0,                  0, 16},
   { 7,  "YUV422 - YUV422 capture",                        1.5,    YUV422ToRGB24,                  0, 16},
   { 8,  "YUYV",                                           2.0,      YUYVToRGB24,                  0, 16},
   { 9,  "UYVY - The great thing about standards is ...",  0.0,                0,                  0, 16},
   {10,  "YUV420",                                         1.5,  ccvt_420p_rgb24,                  0, 16},
   {11,  "YUV411 - YUV411 capture",                        0.0,                0,                  0, 12},
   {12,  "RAW - RAW capture (BT848)",                      0.0,                0,                  0,  8},
   {13,  "YUV422P - YUV 4:2:2 Planar",                     0.0,                0,                  0, 16},
   {14,  "YUV411P - YUV 4:1:1 Planar",                     0.0,                0,                  0, 12},
   {15,  "YUV420P - YUV 4:2:0 Planar",                     1.5,  ccvt_420p_rgb24,                  0, 12},
   {16,  "YUV410P - YUV 4:1:0 Planar",                     0.0,                0,                  0,  9}
};


inline float paletteBytesPerPixel(int palette) {
   float bytesPerPixel;
   if (palette < 1 || palette > 16) {
      fprintf(stdout, "* Invalid palette=%d\n", palette);
      return 0;
   }

   bytesPerPixel = palette_info_list[palette].bytesPerPixel;
   if (bytesPerPixel == 0) {
      fprintf(stdout, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   return bytesPerPixel;
}


inline char* paletteName(int palette) {
   if (palette == 0) {
      return "*automatic*";
   }
   if (palette < 0 || palette > 16) {
      return "*UNKOWN*";
   }
   
   return palette_info_list[palette].name;
}

inline Converter converterFunction(const int palette) {
   Converter funct;

   if (palette < 1 || palette > 16) {
      fprintf(stdout, "* Invalid palette=%d\n", palette);
      return 0;
   }

   funct = palette_info_list[palette].converterFunction24;
   if (funct == 0) {
      fprintf(stdout, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   return funct;
}

inline int paletteConvert24(const int palette,
                            const int width, const int height,
                            const void *src, void *dst) {
   Converter funct = converterFunction(palette);
   if (funct == 0) {
      return 0;
   }

   funct(width, height, src, dst);
   return 1;
}


inline int paletteDepth(int palette) {
   int depth;
   if (palette < 1 || palette > 16) {
      fprintf(stdout, "* Invalid palette=%d\n", palette);
      return 0;
   }

   depth = palette_info_list[palette].depth;
   if (depth == 0) {
      fprintf(stdout, "* Palette=%d not yet supported\n", palette);
      return 0;
   }

   return depth;
}
