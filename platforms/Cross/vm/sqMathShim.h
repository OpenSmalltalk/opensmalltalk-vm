/****************************************************************************
*   A shim between the VM and math.h to allow provision of cross-platform
*	bit-identical floating point.
*/

#if BIT_IDENTICAL_FLOATING_POINT
# include "../third-party/fdlibm/fdlibm.h"
# define acos __ieee754_acos
# define acosh __ieee754_acosh
# define asin __ieee754_asin
# define atan2 __ieee754_atan2
# define atanh __ieee754_atanh
# define cosh __ieee754_cosh
# define exp __ieee754_exp
# define fmod __ieee754_fmod
# define gamma_r __ieee754_gamma_r
# define hypot __ieee754_hypot
# define j0 __ieee754_j0
# define j1 __ieee754_j1
# define jn __ieee754_jn
# define lgamma_r __ieee754_lgamma_r
# define log __ieee754_log
# define log10 __ieee754_log10
# define remainder __ieee754_remainder
# define scalb __ieee754_scalb
# define sinh __ieee754_sinh
# define sqrt __ieee754_sqrt
# define y0 __ieee754_y0
# define y1 __ieee754_y1
# define yn __ieee754_yn
#endif
