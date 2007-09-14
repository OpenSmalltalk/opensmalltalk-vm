#ifndef _PALETTES_H
#define _PALETTES_H

typedef void (*Converter)(int width, int height, const void *src, void *dst);


inline char*     paletteName         (int palette);
inline float     paletteBytesPerPixel(int palette);
inline int       paletteDepth        (int palette);
inline Converter converterFunction   (const int palette);
inline int       paletteConvert24    (int palette,
                                      int width, int height,
                                      const void *src, void *dst);

#endif
