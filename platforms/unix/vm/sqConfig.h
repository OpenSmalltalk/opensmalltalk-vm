/* Unix sqConfig.h -- platform identification and configuration */

/* This file has been superseded by autoconf for Unix variants. */

#include "config.h"

#ifndef UNIX
# define UNIX
#endif

#if !defined(LSB_FIRST)
#error  "LSB_FIRST is undefined. Used for setting platform endianesness!"
#endif


#if LSB_FIRST
# define VMBIGENDIAN 0
#else
# define VMBIGENDIAN 1
#endif
