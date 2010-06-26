#ifndef _SKYEYE_MIPS_TYPES_H_
#define _SKYEYE_MIPS_TYPES_H_

#include "inttypes.h"

/* Fundamental types */

typedef UInt32 VA;		//Virtual address
typedef UInt32 PA;		//Physical address
typedef UInt32 Instr;		//Instruction

/* Width of the MIPS address space.
 * static const int paddr_width = 36;
 */
#define paddr_width 			32

/* Caching algorithm numbers */
#define noncoherent_write_through	0
#define noncoherent_write_allocate	1
#define uncached			2
#define noncoherent_write_back		3
#define exclusive			4
#define exclusive_on_write		5
#define update_on_write			6

/* Hardware data types */
#define byte				0
#define halfword			1
#define triplebyte			2
#define word				3
#define quintibyte			4
#define sextibyte			5
#define septibyte			6
#define doubleword			7

/* The caching algorithm is stored as part of the physical address,
 * using the same encoding as that of XKPHYS address space region.
 */
static int 
coherency_algorithm(PA pa) //Shi yang 2006-08-08
{ 
	return bits(pa, 31, 29); 
}

#endif //end of _SKYEYE_MIPS_TYPES_H_
