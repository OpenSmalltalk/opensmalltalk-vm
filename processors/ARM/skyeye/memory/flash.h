#ifndef __MEMORY_FLASH_H__
#define __MEMORY_FLASH_H__
#include "skyeye_defs.h"
char flash_read(short size, int offset, uint32_t * value);

char flash_write(short size, int offset, uint32_t value);

#endif
