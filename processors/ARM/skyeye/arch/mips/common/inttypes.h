#ifndef _SKYEYE_MIPS_INTTYPES_H_
#define _SKYEYE_MIPS_INTTYPES_H_

#include <stdlib.h>
#include "../../../utils/config/skyeye_types.h"

/* This header defines a set of minimum-width integer types. There is no need
 * for fixed-width types, although in many places it may improve performance.
 * There are four minimum-width signed types Int8, Int16, Int32 and Int64, and
 * four corresponding unsigned types UInt8, UInt16, UInt32 and UInt64.
 * Currently, two models are supported, ANSI (use ANSI restrictions on types
 * up to 32 bit and some unportable 64 bit type) and SIM64 (32 bit integers
 * and 64 bit longs). The first is currently supported only on GCC and TenDRA
 * as well as any C99-compatible compilers. Note that all eight types MUST be
 * distinct, as they are frequently used in overload resolution.
 */

typedef signed char Int8;
typedef unsigned char UInt8;

typedef signed short Int16;
typedef unsigned short UInt16;

typedef signed int Int32;
typedef unsigned int UInt32;

typedef signed long long Int64;
typedef unsigned long long UInt64;

typedef UInt64  ClockValue;

/* Useful multiplier suffixes */
#define  KB 		1024
#define  MB 		1024*KB
#define  GB 		1024*MB
#define  TB 		1024*GB

/* Interfaces to ANSI # and ## preprocessing operators.  The STR2() and
 * GLUE2() differ from STR() and GLUE() in that the later macro-expand the
 * arguments before applying the operator.
 */
#define STR2(x)		#x
#define STR(x)		STR2(x)
#define GLUE2(x,y)	x##y
#define GLUE(x,y)	GLUE2(x, y)

/* Two macros used to construct fixed-width constants from unsuffixed
 * literals. They serve two purposes: (1) to make it possible to define
 * portable 64 bit constants on 32 bit systems, and (2) to make huge constant
 * easier to read.
 */
#define C32(a,b)							  \
	((UInt32)((UInt32)GLUE2(0x,a) << 16 | (UInt32)GLUE2(0x,b)))

#define C64(a,b,c,d)							  \
	((UInt64)((UInt64)(a) << 48 | (UInt64)(b) << 32 | \
		  (UInt64)(c) << 16 | (UInt64)(d)))

#define is_power_of_two(x) \
	({					\
		typeof((x)) _x = (x);	\
		((x) & -(x)) == (x);	\
	})
	
#define round_down(x, size) (x & -(Int32)size)

#define bitmask(n) ((UInt32)(1) << n) 

#define bitsmask(n, m) ((~(UInt32)0 ) >> (m) << (31 - (n) + (m)) >> (31 - (n)))

#define bit(x, n) (((x) >> n) & 1)

#define clear_bit(x, n) ((x) & ~bitmask(n))

#define set_bit(x, n) ((x) | bitmask(n))

#define bits(x, n, m) \
	({		\
	UInt32 y = (x);	\
	y << (31 - (n)) >> (31 - (n) + (m)); \
	})

#define clear_bits(x, n, m) ((x) & ~bitsmask((n), (m)))

#define set_bits(x, n, m) ((x) | bitsmask((n), (m)))

#define copy_bits(x, y, n, m) (clear_bits((x), (n), (m)) | (bits((y), ((n) - (m)), (int)0) << m))

#define zero_extend(x, n) (bits((x), (n) - 1, 0))

#define MulResult(x, y) \
{\
	mstate->hi = (x);\
	mstate->lo = (y);\
}

#define multiply(a, b) \
{\
	const int n = 8 * sizeof(typeof(a));\
	UInt32 _x = (a), _y = (b);\
	unsigned long long _z = _x * _y;\
	MulResult(bits(_z, 2*n-1, n), bits(_z, n-1, 0));\
}

#define DivResult(x,y) \
{\
	mstate->lo = x;\
	mstate->hi = y;\
}
#define divide(a, b) \
{\
    	const size_t n = 8 * sizeof(typeof(a));\
    	if (n < sizeof(int)) {\
		div_t r = div((int)(a), (int)(b));\
		DivResult(r.quot, r.rem)\
    	}\
    	else if (n < sizeof(long)) {\
		ldiv_t r = ldiv((long)(a), (long)(b));\
		DivResult(r.quot, r.rem)\
    	}\
    	else {\
		DivResult(a / b, a % b)\
    	}\
}


#endif //end of _SKYEYE_MIPS_INTTYPES_H_
