/* @(#)fdlibm.h 1.5 04/04/22 */
/*
 * ====================================================
 * Copyright (C) 2004 by Sun Microsystems, Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice 
 * is preserved.
 * ====================================================
 */


#ifndef __FDLIBM_H
#define __FDLIBM_H

#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#define __getBits(i,x) do { uint64_t __j; double __f=x; memcpy(&__j,&__f,sizeof __j); i=__j; } while(0)
#define __setBits(x,i) do { uint64_t __j=i; double __f; memcpy(&__f,&__j,sizeof __f); x=__f; } while(0)

#define __getHI(i,x) do { uint64_t __i; __getBits(__i,x); i=(uint32_t)( __i >> 32); } while(0)
#define __getLO(i,x) do { uint64_t __i; __getBits(__i,x); i=(uint32_t)( __i & 0xFFFFFFFFU); } while(0)
#define __setHI(x,i) do { uint64_t __i; __getBits(__i,x); __i=(__i & 0xFFFFFFFFULL) | (((uint64_t)i) << 32); __setBits(x,__i); } while(0)
#define __setLO(x,i) do { uint64_t __i; __getBits(__i,x); __i=(__i & 0xFFFFFFFF00000000ULL) | ((uint32_t)(i)); __setBits(x,__i); } while(0)
#define __setHILO(x,h,l) do { uint64_t __i=(((uint64_t)h) << 32) | ((uint32_t)(l)); __setBits(x,__i); } while(0)

/* flip the sign of x */
#define __flipSign(x) do { uint64_t __i; __getBits(__i,x); __i=( __i ^ 0x8000000000000000ULL); __setBits(x,__i); } while(0)

/* increment the exponent of x by k */
#define __incExp(x,k) do { uint64_t __i; __getBits(__i,x); __i=__i + (((uint64_t)k) << 52); __setBits(x,__i); } while(0)

/*
 * ANSI/POSIX
 */

extern int signgam;

#define MAXFLOAT        ((float)3.40282346638528860e+38)

enum fdversion {fdlibm_ieee = -1, fdlibm_svid, fdlibm_xopen, fdlibm_posix};

#define _LIB_VERSION_TYPE enum fdversion
#define _LIB_VERSION _fdlib_version  

/* if global variable _LIB_VERSION is not desirable, one may 
 * change the following to be a constant by: 
 *      #define _LIB_VERSION_TYPE const enum version
 * In that case, after one initializes the value _LIB_VERSION (see
 * s_lib_version.c) during compile time, it cannot be modified
 * in the middle of a program
 */ 
extern  _LIB_VERSION_TYPE  _LIB_VERSION;

#define _IEEE_  fdlibm_ieee
#define _SVID_  fdlibm_svid
#define _XOPEN_ fdlibm_xopen
#define _POSIX_ fdlibm_posix

#ifndef __MATH_H__ /* math.h may define this */
struct exception {
        int type;
        char *name;
        double arg1;
        double arg2;
        double retval;
};
#endif

#define HUGE            MAXFLOAT

/* 
 * set X_TLOSS = pi*2**52, which is possibly defined in <values.h>
 * (one may replace the following line by "#include <values.h>")
 */

#define X_TLOSS         1.41484755040568800000e+16 

#if !defined(DOMAIN)
# define DOMAIN          1
# define SING            2
# define OVERFLOW        3
# define UNDERFLOW       4
# define TLOSS           5
# define PLOSS           6
#endif

/*
 * ANSI/POSIX
 */
/* define only __ieee754_ interfaces to avoid conflicts with base math.h.
 * _IEEE_LIBM is defined only when the library is built.
 */
#if defined(_IEEE_LIBM)
extern double acos(double);
extern double asin(double);
extern double atan(double);
extern double atan2(double, double);
extern double cos(double);
extern double sin(double);
extern double tan(double);

extern double cosh(double);
extern double sinh(double);
extern double tanh(double);

extern double exp(double);
extern double frexp(double, int *);
extern double ldexp(double, int);
extern double log(double);
extern double log10(double);
extern double modf(double, double *);

extern double pow(double, double);
extern double sqrt(double);

extern double ceil(double);
extern double fabs(double);
extern double floor(double);
extern double fmod(double, double);

extern double erf(double);
extern double erfc(double);
extern double gamma(double);
extern double hypot(double, double);
extern int isnan(double);
extern int finite(double);
extern double j0(double);
extern double j1(double);
extern double jn(int, double);
extern double lgamma(double);
extern double y0(double);
extern double y1(double);
extern double yn(int, double);

extern double acosh(double);
extern double asinh(double);
extern double atanh(double);
extern double cbrt(double);
extern double logb(double);
extern double nextafter(double, double);
extern double remainder(double, double);
# ifdef _SCALB_INT
extern double scalb(double, int);
# else
extern double scalb(double, double);
# endif

extern int matherr(struct exception *);

/*
 * IEEE Test Vector
 */
extern double significand(double);

/*
 * Functions callable from C, intended to support IEEE arithmetic.
 */
extern double copysign(double, double);
extern int ilogb(double);
extern double rint(double);
extern double scalbn(double, int);

/*
 * BSD math library entry points
 */
extern double expm1(double);
extern double log1p(double);

/*
 * Reentrant version of gamma & lgamma; passes signgam back by reference
 * as the second argument; user must allocate space for signgam.
 */
# ifdef _REENTRANT
extern double gamma_r(double, int *);
extern double lgamma_r(double, int *);
# endif  /* _REENTRANT */
#endif /* _IEEE_LIBM */

/* ieee style elementary functions */
extern double __ieee754_sqrt(double);                     
extern double __ieee754_acos(double);                     
extern double __ieee754_acosh(double);                    
extern double __ieee754_log(double);                      
extern double __ieee754_atanh(double);                    
extern double __ieee754_asin(double);                     
extern double __ieee754_atan2(double,double);                     
extern double __ieee754_exp(double);
extern double __ieee754_cosh(double);
extern double __ieee754_fmod(double,double);
extern double __ieee754_pow(double,double);
extern double __ieee754_lgamma_r(double,int *);
extern double __ieee754_gamma_r(double,int *);
extern double __ieee754_lgamma(double);
extern double __ieee754_gamma(double);
extern double __ieee754_log10(double);
extern double __ieee754_sinh(double);
extern double __ieee754_hypot(double,double);
extern double __ieee754_j0(double);
extern double __ieee754_j1(double);
extern double __ieee754_y0(double);
extern double __ieee754_y1(double);
extern double __ieee754_jn(int,double);
extern double __ieee754_yn(int,double);
extern double __ieee754_remainder(double,double);
extern int    __ieee754_rem_pio2(double,double*);
#ifdef _SCALB_INT
extern double __ieee754_scalb(double,int);
#else
extern double __ieee754_scalb(double,double);
#endif

/* fdlibm kernel function */
extern double __kernel_standard(double,double,int);       
extern double __kernel_sin(double,double,int);
extern double __kernel_cos(double,double);
extern double __kernel_tan(double,double,int);
extern int    __kernel_rem_pio2(double*,double*,int,int,int,const int*);

#ifdef __cplusplus
}
#endif

#endif /* __FDLIBM_H */
