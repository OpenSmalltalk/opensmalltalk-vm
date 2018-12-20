#ifndef _LIBC_WRAPPER_H
#define _LIBC_WRAPPER_H

/* avoid conflicts with squeak print function */
#define print p9_print

#include <u.h>
#include <libc.h>

#undef print

#endif
