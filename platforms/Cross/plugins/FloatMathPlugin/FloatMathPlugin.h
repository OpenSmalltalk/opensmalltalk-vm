/* we only declare those functions from fdlibm that we actually use
   and avoid including fdlibm.h alltogether as it conflicts with math.h */

/* #define NO_ISNAN -- do NOT define this by default but in command line*/

#if !defined(NO_ISNAN) && !defined(isnan)
/* by default we use fdlibm's isnan() */
extern int isnan(double);
#endif
extern double __ieee754_sqrt(double);

extern double __ieee754_acos(double);
extern double __ieee754_acosh(double);
extern double __ieee754_asin(double);
extern double __ieee754_asinh(double);
extern double __ieee754_atan(double);
extern double __ieee754_atan2(double,double);
extern double __ieee754_atanh(double);
extern double __ieee754_cos(double);
extern double __ieee754_cosh(double);
extern double __ieee754_exp(double);
extern double __ieee754_fmod(double,double);
extern double __ieee754_modf(double,double*);
extern double __ieee754_hypot(double,double);
extern double __ieee754_log10(double);
extern double __ieee754_log(double);
extern double __ieee754_pow(double,double);
extern double __ieee754_sin(double);
extern double __ieee754_sinh(double);
extern double __ieee754_sqrt(double);
extern double __ieee754_tan(double);
extern double __ieee754_tanh(double);
extern double __ieee754_ldexp(double, int);

