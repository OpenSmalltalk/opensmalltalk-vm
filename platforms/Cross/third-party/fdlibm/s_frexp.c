/* @(#)s_frexp.c 1.4 95/01/18 */
/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunSoft, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice 
 * is preserved.
 * ====================================================
 */

/*
 * for non-zero x 
 *      x = frexp(arg,&exp);
 * return a double fp quantity x such that 0.5 <= |x| <1.0
 * and the corresponding binary exponent "exp". That is
 *      arg = x*2^exp.
 * If arg is inf, 0.0, or NaN, then frexp(arg,&exp) returns arg 
 * with *exp=0. 
 */

#include "fdlibm.h"

static const double
two54 =  1.80143985094819840000e+16; /* 0x43500000, 0x00000000 */

double frexp(double x, int *eptr)
{
        int  hx, ix, lx;
        __getHI(hx,x);
        ix = 0x7fffffff&hx;
        __getLO(lx,x);
        *eptr = 0;
        if(ix>=0x7ff00000||((ix|lx)==0)) return x;      /* 0,inf,nan */
        if (ix<0x00100000) {            /* subnormal */
            x *= two54;
            __getHI(hx,x);
            ix = hx&0x7fffffff;
            *eptr = -54;
        }
        *eptr += (ix>>20)-1022;
        hx = (hx&0x800fffffU)|0x3fe00000;
        __setHI(x, hx);
        return x;
}
