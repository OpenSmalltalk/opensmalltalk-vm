#ifndef __TYPES_H__
#define __TYPES_H__

#include <sys/types.h>
#include <stdint.h>

#ifndef __BEOS__
typedef enum{
	false = 0,
	true = 1
}bool;

#define uint64 uint64_t
#define uint32 uint32_t
#define uint16 uint16_t
#define uint8 uint8_t
#else
/* HEY, bool/uint8/uint16/uint32/uint64 typedef'd by system */
#include <be/support/SupportDefs.h>
#endif

#define sint64 int64_t
#define sint32 int32_t
#define sint16 int16_t
#define sint8 int8_t

#define byte int8_t
#define uint uint32_t

typedef struct uint128 {
        uint64 l;
        uint64 h;
} uint128;
typedef struct sint128 {
        sint64 l;
        sint64 h;
} sint128;

#define FASTCALL 

#define IO_MEM_ACCESS_OK        0
#define IO_MEM_ACCESS_EXC       1
#define IO_MEM_ACCESS_FATAL     2

#define FUNCTION_CONST const

#endif
