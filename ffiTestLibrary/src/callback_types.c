#include "callbacks.h"

/************************************************************
*** Macros
************************************************************/

// Macros to define common identity id_type() functions to test arguments and return types
#define simple_callback_f(TYPE) simple_callback_with_name_f(TYPE, TYPE)
#define simple_callback_with_name_f(TYPE, NAME) void simple_callback_f_##NAME(simple_callback_##NAME fun, TYPE value){ \
	fun(value); \
}

#define simple_callback_byRef_f(TYPE) simple_callback_byRef_with_name_f(TYPE, TYPE)
#define simple_callback_byRef_with_name_f(TYPE, NAME) void simple_callback_byRef_f_##NAME(simple_callback_byRef_##NAME fun, TYPE* value){ \
	fun(value); \
}

#define simple_callback_byCopy_and_ref_f(TYPE) simple_callback_f(TYPE) \
		simple_callback_byRef_f(TYPE)


/************************************************************
*** Floating point number types
************************************************************/

simple_callback_f(float)
simple_callback_f(double)
  
/************************************************************
*** Character types
************************************************************/
simple_callback_f(char)
simple_callback_with_name_f(unsigned char, uchar)

/************************************************************
*** Signed Integer types
************************************************************/
simple_callback_f(short)
simple_callback_f(int)
simple_callback_f(int8_t)
simple_callback_f(int16_t)
simple_callback_f(int32_t)
simple_callback_f(int64_t)
simple_callback_f(long)
simple_callback_with_name_f(long long, longlong)

/************************************************************
*** Unsigned Integer types
************************************************************/
simple_callback_with_name_f(unsigned short, ushort)
simple_callback_with_name_f(unsigned int, uint)
simple_callback_f(uint8_t)
simple_callback_f(uint16_t)
simple_callback_f(uint32_t)
simple_callback_f(uint64_t)
simple_callback_with_name_f(unsigned long, ulong)
simple_callback_with_name_f(unsigned long long, ulonglong)

/************************************************************
*** Pointer types
************************************************************/
  
simple_callback_with_name_f(void*, pointer)

/************************************************************
*** Struct types
************************************************************/

simple_callback_byCopy_and_ref(NESTED_STRUCTS)
simple_callback_byCopy_and_ref(LONG_STRUCT)
simple_callback_byCopy_and_ref(POINT)

/************************************************************
*** Derived types, e.g., size_t, String, etc
************************************************************/
simple_callback_f(size_t)
