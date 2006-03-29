#ifndef CROQUET_PLUGIN_H
#define CROQUET_PLUGIN_H
/* CroquetPlugin.h include file */

/* Include MD5 code for primitives */
#include "md5.h"

/* 
   ioGatherEntropy:
   Fill a buffer with high-quality entropy. Return true on success, false 
   if no high-quality source is available or if the source couldn't be 
   used for some reason. On *nix platforms, the Right Thing To Do is
   to use /dev/urandom for filling the buffer so the implementation gets
   trivial (open /dev/urandom, read bufSize bytes, return true).
   Arguments:
     bufPtr  - the buffer to fill
     bufSize - the number of bytes to place in the buffer
   Return value:
     Non-zero if successful, zero otherwise.
*/
int ioGatherEntropy(char *bufPtr, int bufSize);

#endif /* CROQUET_PLUGIN_H */
