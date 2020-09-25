/* @(#)s_fabs.c 1.3 95/01/18 */
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
 * fabs(x) returns the absolute value of x.
 */

#include "fdlibm.h"

double fabs(double x)
{
        unsigned hx;
        __getHI(hx,x);
        __setHI(x,hx & 0x7fffffff);
        return x;
}
