/*
 * Copyright 2008 Cadence Design Systems, Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
 */
/*
 *  platforms/Cross/plugins/IA32ABI/ia32abi.h
 *
 *  Written by Eliot Miranda 11/07.
 *
 * Call foreign functons returning results in either %eax, %edx (Integral)
 * or %f0 (Float, Double).  
 *
 * The primitive will have signatures of the form
 *
 *	<Anywhere> primFFIResult: result <Alien> call: functionAddress <Alien>
 *	  with: firstArg <Alien> ... with: lastArg <Alien>
 *		<primitive: 'primCallOutXXX' module: 'IA32ABI'>
 *
 *	result <Alien> primFFICall: functionAddress <Alien>
 *	  with: firstArg <Alien> ... with: lastArg <Alien>
 *		<primitive: 'primCallOutXXX' module: 'IA32ABI'>
 *
 *	functionAddress <Alien> primFFICallResult: result <Alien>
 *	  with: firstArg <Alien> ... with: lastArg <Alien>
 *		<primitive: 'primCallOutXXX' module: 'IA32ABI'>
 */

#define SIGNATURE	sqInt *argVector/* call args on stack or in array */, \
					int numArgs,	/* arg count of function to call   */ \
					int funcOffset, /* stack offset of func Alien   */ \
					int resultOffset/* stack offset of result Alien */

extern sqInt callIA32IntegralReturn(SIGNATURE);
extern sqInt callIA32FloatReturn   (SIGNATURE);
extern sqInt callIA32DoubleReturn  (SIGNATURE);
extern long  thunkEntry            (void *thunkp, long *stackp);
extern void *allocateExecutablePage(long *pagesize);

/*
 * Returning values from callbacks is done through a CallBackReturnSpec
 * which contains a type tag and values.  It is designed to be overlaid upon
 * an FFICallbackReturnProxy created at the Smalltalk level to return values.
 */
typedef  struct {
	long type;
# define retint32  0
# define retint64  1
# define retdouble 2
# define retstruct 3
	long _pad; /* so no doubt that valflt64 & valint32 et al are at byte 8 */
union {
		long valint32;
		struct { long low, high; } valint64;
		double valflt64;
		struct { void *addr; long size; } valstruct;
	} rvs;
} CallBackReturnSpec;

/* Use the most minimal setjmp/longjmp pair available; no signal handling
 * wanted or necessary.
 */
#if !defined(WIN32)
# define setjmp _setjmp
# define longjmp _longjmp
#endif
