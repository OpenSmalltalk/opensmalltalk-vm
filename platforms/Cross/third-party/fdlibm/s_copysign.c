/* @(#)s_copysign.c 1.3 95/01/18 */
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
 * copysign(double x, double y)
 * copysign(x,y) returns a value with the magnitude of x and
 * with the sign bit of y.
 */

#include "fdlibm.h"

double copysign(double x, double y)
{
        unsigned int hx,hy;
        __getHI(hx,x);
        __getHI(hy,y);
        __setHI(x, (hx&0x7fffffff)|(hy&0x80000000U));
        return x;
}
