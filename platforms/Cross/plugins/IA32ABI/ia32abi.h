/*
 *  platforms/Cross/plugins/IA32ABI/ia32abi.h
 *
 *  Written by Eliot Miranda 11/07.
 *  Copyright 2007 Cadence Design Systems. All rights reserved.
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

/* Use the most minimal setjmp/longjmp pair available; no signal handling
 * wanted or necessary.
 */
#if !defined(WIN32)
# define setjmp _setjmp
# define longjmp _longjmp
#endif
