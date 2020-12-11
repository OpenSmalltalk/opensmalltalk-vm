#ifndef CALLBACKS_H
#define CALLBACKS_H

#include "testLibrary.h"

/************************************************************
*** Macros
************************************************************/

// Macros to define common identity id_type() functions to test arguments and return types
#define simple_callback(TYPE) simple_callback_with_name(TYPE, TYPE)
#define simple_callback_with_name(TYPE, NAME) typedef TYPE (*simple_callback_##NAME)(TYPE);

#define simple_callback_byRef(TYPE) simple_callback_byRef_with_name(TYPE, TYPE)
#define simple_callback_byRef_with_name(TYPE, NAME) typedef TYPE (*simple_callback_byRef_##NAME)(TYPE*);

#define simple_callback_byCopy_and_ref(TYPE) simple_callback(TYPE) \
		simple_callback_byRef(TYPE)

/************************************************************
*** Floating point number types
************************************************************/

simple_callback(float)
simple_callback(double)
  
/************************************************************
*** Character types
************************************************************/
simple_callback(char)
simple_callback_with_name(unsigned char, uchar)

/************************************************************
*** Signed Integer types
************************************************************/
simple_callback(short)
simple_callback(int)
simple_callback(int8_t)
simple_callback(int16_t)
simple_callback(int32_t)
simple_callback(int64_t)
simple_callback(long)
simple_callback_with_name(long long, longlong)

/************************************************************
*** Unsigned Integer types
************************************************************/
simple_callback_with_name(unsigned short, ushort)
simple_callback_with_name(unsigned int, uint)
simple_callback(uint8_t)
simple_callback(uint16_t)
simple_callback(uint32_t)
simple_callback(uint64_t)
simple_callback_with_name(unsigned long, ulong)
simple_callback_with_name(unsigned long long, ulonglong)

/************************************************************
*** Pointer types
************************************************************/
  
simple_callback_with_name(void*, pointer)

/************************************************************
*** Struct types
************************************************************/

simple_callback_byCopy_and_ref(NESTED_STRUCTS)
simple_callback_byCopy_and_ref(LONG_STRUCT)
simple_callback_byCopy_and_ref(POINT)

/************************************************************
*** Derived types, e.g., size_t, String, etc
************************************************************/
simple_callback(size_t)

// Deprecated
typedef int (*SIMPLE_CALLBACK)(int);

#endif
