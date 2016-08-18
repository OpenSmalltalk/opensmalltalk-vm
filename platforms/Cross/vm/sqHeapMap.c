/****************************************************************************
 *   PROJECT: Maintain a heap map for heap debugging, 1 bit per 32-bit word
 *            The space overhead is a maximum of 1/32 of the address space.
 *   FILE:    sqHeapMap.c
 *   CONTENT: 
 *
 *   AUTHOR:  Eliot Miranda
 *   ADDRESS: 
 *   EMAIL:   eliot.miranda@gmail.com
 *
 *   NOTES: The idea is to check for heap pointer integrity.  We scan the heap
 *          setting a bit in the map for each object's base header.  We then
 *          scan the heap checking that each pointer points to a base header by
 *          checking for a 1 in the heap map.
 *
 *          We can also check for leaks by scanning a third time and clearing
 *          the header bit.  Any remaining set bits indicate an unreferenced
 *          object that should have been collected.
 *
 ****************************************************************************/

#include "sqMemoryAccess.h" 
#include "sqAssert.h" /* for error */

#include <stdlib.h>
#include <string.h> /* for memset */
#include <stdio.h> /* for perror */

#define ulong usqIntptr_t   /* enough for holding a pointer - unsigned long does not fit in LLP64 */
#define uchar unsigned char

#if SQ_IMAGE32
/*
 * 32-bit address space = 2^32 bytes = 2^30 words.  If we have 256 root pages
 * then each page needs to cover 2^30 / 256 words = 8 megawords.  Each 8-bit
 * byte in the leak map covers 8 words.  So each page needs to be 8M / 8 bytes
 * = 512k bytes per page.
 */
 
#define NUMPAGES 256

static uchar *mapPages[NUMPAGES] = { 0, };

#define PAGESIZE (1024*1024)
#define PAGESHIFT 24
#define PAGEMASK 0xFFFFFF
#define LOGWORDSIZE 2
#define LOGBITSPERBYTE 3
#define PAGEINDEX(a) ((a) >> PAGESHIFT)
#define BYTEINDEX(a) (((a) & PAGEMASK) >> (LOGWORDSIZE + LOGBITSPERBYTE))
#define BITINDEX(a) (((a) >> LOGWORDSIZE) & ((1<<LOGBITSPERBYTE)-1))

/*
 * Answer non-zero if the heapMap is set at wordPointer, 0 otherwise
 */
int
heapMapAtWord(void *wordPointer)
{
	ulong address = (ulong)wordPointer;
	uchar *page = mapPages[PAGEINDEX(address)];
	if ((address & ((1<<LOGWORDSIZE)-1)))
		error("misaligned word");
	return page
		? page[BYTEINDEX(address)] & (1 << BITINDEX(address))
		: 0;
}

/*
 * Set the value in the map at wordPointer to bit.
 */
void
heapMapAtWordPut(void *wordPointer, int bit)
{
	ulong address = (ulong)wordPointer;
	uchar *page = mapPages[PAGEINDEX(address)];
	if ((address & ((1<<LOGWORDSIZE)-1)))
		error("misaligned word");
	if (!page) {
		if (!(page = malloc(PAGESIZE))) {
			perror("heapMap malloc");
			exit(1);
		}
		mapPages[PAGEINDEX(address)] = page;
		memset(page,0,PAGESIZE);
	}
	if (bit)
		page[BYTEINDEX(address)] |= 1 << BITINDEX(address);
	else
		page[BYTEINDEX(address)] &= (uchar)-1 ^ (1 << BITINDEX(address));
}

/*
 * Clear the heap map to zero.
 */
void
clearHeapMap(void)
{
	int i;

	for (i = 0; i < NUMPAGES; i++)
		if (mapPages[i])
			memset(mapPages[i],0,PAGESIZE);
}
#else /* SQ_IMAGE32 */
/*
 * 64-bit address space = 2^64 bytes = 2^61 64-bit words at a bit per 64-bit
 * word.  So we need to be able to cover 2^58 bytes.  If we have e.g. 65536
 * root pages, for a minimum overhead of 512k then each page needs to cover
 * 2^58 / 65536 words = 2^42 bytes per page, so we need a two-level page table.
 * We split the table 16 bits for the root, 19 bits for intermediate pages (an
 * overhead of 4mb per second-level page), leaving 2^23 byts per page, 8mb per
 * page.
 */
 
#define NUMROOTPAGES 65536

static uchar **mapPages[NUMROOTPAGES] = { 0, };

#define PAGESIZE (8*1024*1024)
#define PAGESHIFT 26 /* 8mb = 2^23, + 2^3 for 64-bit units = 2^26 */
#define PAGEMASK 0x3FFFFFF
#define DIRECTORYSIZE ((1 << 19) * sizeof(void *))
#define DIRECTORYSHIFT (PAGESHIFT + 19)
#define DIRECTORYMASK 0x7FFFF
#define LOGWORDSIZE 3
#define LOGBITSPERBYTE 3

#define BITINDEX(a) (((a) >> LOGWORDSIZE) & ((1<<LOGBITSPERBYTE)-1))
#define BYTEINDEX(a) (((a) & PAGEMASK) >> (LOGWORDSIZE + LOGBITSPERBYTE))
#define PAGEINDEX(a) (((a) >> PAGESHIFT) & DIRECTORYMASK)
#define DIRECTORYINDEX(a) ((a) >> DIRECTORYSHIFT)

/*
 * Answer non-zero if the heapMap is set at wordPointer, 0 otherwise
 */
int
heapMapAtWord(void *wordPointer)
{
	ulong address = (ulong)wordPointer;
	uchar **directory, *page;
	if ((address & ((1<<LOGWORDSIZE)-1)))
		error("misaligned word");
	if (!(directory = mapPages[DIRECTORYINDEX(address)]))
		return 0;
	page = directory[PAGEINDEX(address)];
	return page
		? page[BYTEINDEX(address)] & (1 << BITINDEX(address))
		: 0;
}

/*
 * Set the value in the map at wordPointer to bit.
 */
void
heapMapAtWordPut(void *wordPointer, int bit)
{
	ulong address = (ulong)wordPointer;
	uchar **directory, *page;
	if ((address & ((1<<LOGWORDSIZE)-1)))
		error("misaligned word");
	if (!(directory = mapPages[DIRECTORYINDEX(address)])) {
		if (!(directory = malloc(DIRECTORYSIZE))) {
			perror("heapMap malloc");
			exit(1);
		}
		mapPages[DIRECTORYINDEX(address)] = directory;
		memset(directory,0,DIRECTORYSIZE);
	}
	if (!(page = directory[PAGEINDEX(address)])) {
		if (!(page = malloc(PAGESIZE))) {
			perror("heapMap malloc");
			exit(1);
		}
		directory[PAGEINDEX(address)] = page;
		memset(page,0,PAGESIZE);
	}
	if (bit)
		page[BYTEINDEX(address)] |= 1 << BITINDEX(address);
	else
		page[BYTEINDEX(address)] &= (uchar)-1 ^ (1 << BITINDEX(address));
}

/*
 * Clear the heap map to zero.
 */
void
clearHeapMap(void)
{
	long i, j;
	uchar **directory, *page;

	for (i = 0; i < NUMROOTPAGES; i++)
		if ((directory = mapPages[i]))
			for (j = 0; j < DIRECTORYSIZE / sizeof(void *); j++)
				if ((page = directory[j]))
					memset(page,0,PAGESIZE);
}
#endif /* SQ_IMAGE32 */
