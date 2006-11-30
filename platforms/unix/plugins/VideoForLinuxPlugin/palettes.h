
#ifndef _PALETTES_H
#define _PALETTES_H

char* paletteName(int palette);

float paletteBytesPerPixel(int palette);

int paletteDepth(int palette);

int paletteConvert(int palette,
                   int width, int height,
                   const void *src, void *dst);

#endif
