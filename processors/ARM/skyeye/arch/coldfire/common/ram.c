/**********************************/
/*                                */
/*  Copyright 2002, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/

/* RAM and ROM memory modules */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*#define SKYEYE_DBGR_OFF*/
#include "coldfire.h"

SKYEYE_DBGR_DEFAULT_CHANNEL(ram);

void ram_init(void);
static void ram_setup(struct _memory_segment *s);
static void rom_setup(struct _memory_segment *s);
static void ram_fini(struct _memory_segment *s);
static char ram_read(struct _memory_segment *s, unsigned int *result, short size, unsigned int offset);
static char ram_write(struct _memory_segment *s, short size, unsigned int offset, unsigned int value);
static char rom_write(struct _memory_segment *s, short size, unsigned int offset, unsigned int value);
static void rom_reset(struct _memory_segment *s);

struct _mem_data {
	char *begin;
	char *end;
	int len;
};
	

void ram_init(void)
{
	memory_module_register("ram", &ram_setup);
	memory_module_register("rom", &rom_setup);
}

static void ram_setup(struct _memory_segment *s)
{
	int len;
	struct _mem_data *mem;
	mem = malloc(sizeof(struct _mem_data));
	
	/* Get the length, which is actually the mask + 1 */
	len = (~s->mask) + 1;
	
	SKYEYE_DBG("len=%x\n", len);
	/* +3 for those long reads at EOM */
	mem->begin=malloc((size_t)(len+3)); 
	mem->end = mem->begin + len /* +3 -3 */;
	SKYEYE_DBG("end=%x\n", mem->end);
	mem->len = len;

	s->data = mem;

	/* Now set the functions to use */
	s->fini = &ram_fini;
	s->read = &ram_read;
	s->write = &ram_write;
	s->reset = NULL;
	s->update = NULL;
}


static void rom_setup(struct _memory_segment *s)
{
	ram_setup(s);
	s->write = &rom_write;
	s->reset = &rom_reset;
}


static void ram_fini(struct _memory_segment *s)
{
	struct _mem_data *mem = (struct _mem_data *)s->data;
	free(mem->begin);
	free(s->name);
	free(s->data);
}

static void rom_reset(struct _memory_segment *s)
{
	struct _mem_data *mem = (struct _mem_data *)s->data;
	int x;
	/* Map out the rom in bigendian */
	SKYEYE_DBG("ROM setup with code_length=%d\n", s->code_len);
	for(x=0;x<s->code_len;x++) {
		SKYEYE_DBG(" code[%d] = 0x%02x\n", x, s->code[x]);
	}
#ifdef UNALIGNED_ACCESS
	#ifndef WORDS_BIGENDIAN
		/* Put them in backards, starting at ram->end+3 */
		for(x=0;x<s->code_len; x++) mem->end[3 - x] = s->code[x];
	#else
		memcpy(mem->begin, s->code, s->code_len);
	#endif
#else
	/* Endianness doesn't matter if we can't do unaligned 
	 *  reads/writes.  We just convert everything to big endian */
	memcpy(mem->begin, s->code, s->code_len);
#endif
		
}

static char ram_read(struct _memory_segment *s, unsigned int *result, 
					short size, unsigned int offset)
{
	struct _mem_data *mem = (struct _mem_data *)s->data;
#ifdef UNALIGNED_ACCESS
	unsigned int *ptr;
	SKYEYE_DBG("size=%d, offset=0x%08lx\n", size, offset);
	#ifndef WORDS_BIGENDIAN
		ptr = (unsigned int *)(mem->end - offset);
	#else
		ptr = (unsigned int *)(mem->begin + offset);
	#endif
	*result = (*ptr) >> (32 - size);
#else
	unsigned char *ptr = (unsigned char *)(mem->begin + offset);
	SKYEYE_DBG("mem->begin=0x%08lx size=%d, offset=0x%08lx, ptr=%p\n", 
			mem->begin, size, offset, ptr);
	if(size == 32)
		*result = (*ptr<<24) | (*(ptr+1)<<16) | (*(ptr+2)<<8) | *(ptr+3);
	else if (size == 16)
		*result = (*ptr<< 8) | *(ptr+1);
	else
		*result = *ptr;
#endif
	SKYEYE_DBG("result=0x%08lx\n", *result);
	return 1;
}

static char ram_write(struct _memory_segment *s, short size, 
			unsigned int offset, unsigned int value)
{
#ifdef UNALIGNED_ACCESS
	void *ptr;
	unsigned int templ;
#else
	unsigned char *ptr;
#endif
	struct _mem_data *mem = (struct _mem_data *)s->data;

	SKYEYE_DBG("s=%p\n", s);
	SKYEYE_DBG("size=%d, offset=0x%08lx, value=0x%08lx\n", size, offset, value);
	/* Normal memory access */
#ifdef UNALIGNED_ACCESS
	#ifndef WORDS_BIGENDIAN
		ptr = (void *)(mem->end - offset);
	#else
		ptr = (void *)(mem->begin + offset);
	#endif
	SKYEYE_DBG("s=%p\n", s);
	SKYEYE_DBG("ptr=%p\n", ptr);
	SKYEYE_DBG("mem->end=%p\n", mem->end);
	if(size == 32) {
		*(unsigned int *)ptr = value;
		return 1;	
	} else if (size == 0x0010) {
/*			*(unsigned short *)ptr = (unsigned short)(value & 0x0000FFFF);*/

		memcpy(&templ, ptr, 4);
		templ &= 0x0000FFFF;
		templ |= (value << 16);
		memcpy(ptr, &templ, 4);
		return 1;	
	} /* Else, 8 bits */ else {
/*		*(unsigned char *)ptr = (unsigned char)(value & 0x000000FF);*/

		memcpy(&templ, ptr, 4);
		templ &= 0x00FFFFFF;
		templ |= (value << 24);
		memcpy(ptr, &templ, 4);
		return 1;	
	}
#else
	ptr = (unsigned char *)(mem->begin + offset);
	SKYEYE_DBG("s=%p\n", s);
	SKYEYE_DBG("ptr=%p\n", ptr);
	SKYEYE_DBG("mem->end=%p\n", mem->end);
	if(size == 32) {
		*ptr 	= (value >> 24) & 0xFF;
		*(ptr+1)= (value >> 16) & 0xFF; 
		*(ptr+2)= (value >>  8) & 0xFF; 
		*(ptr+3)= (value      ) & 0xFF;
		return 1;
	} else if (size == 16) {
		*ptr 	= (value >>  8) & 0xFF;
		*(ptr+1)= (value      ) & 0xFF; 
		return 1;
	} else {
		*ptr 	= (value      ) & 0xFF;
		return 1;
	}
#endif
/*	memcpy(ptr, &templ, 4);*/
	return 0;

}

static char rom_write(struct _memory_segment *s, short size, 
				unsigned int offset, unsigned int value)
{
	SKYEYE_ERR("size=%d, offset=0x%08lx, value=0x%08lx\n", size, offset, value);
	SKYEYE_ERR("Cannot write to ROM, go away.\n");
	return 1;
}
