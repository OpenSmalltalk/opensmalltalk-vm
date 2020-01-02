#ifndef CROQUET_PLUGIN_H
#define CROQUET_PLUGIN_H
/* CroquetPlugin.h include file */

#include "sqMemoryAccess.h"

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
sqInt ioGatherEntropy(char *bufPtr, sqInt bufSize);

/* Imported from tribox.c */
int triBoxOverlap(float minCorner[3],float maxCorner[3],
		  float vert0[3], float vert1[3], float vert2[3]);

/* In-place rearrangement of vertex indices to improve
   vertex cache locality. */		  
int optimizeVertexIndices(int* indices, int triCount);

#endif /* CROQUET_PLUGIN_H */
