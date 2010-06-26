#ifndef __BFIN_IOMEM_H
#define __BFIN_IOMEM_H
#include "types.h"
void put_byte (unsigned char *memory, bu32 addr, bu8 v);
void put_word (unsigned char *memory, bu32 addr, bu16 v);
void put_long (unsigned char *memory, bu32 addr, bu32 v);
bu8 get_byte (unsigned char *memory, bu32 addr);
bu16 get_word (unsigned char *memory, bu32 addr);
bu32 get_long (unsigned char *memory, bu32 addr);
#endif
