/*
 *  sqMacCroquet.c
 *  SqueakCroquet
 *
 *  Created by John M McIntosh on 04/04/06.
 *  Copyright 2006 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *  Licenced under the Squeak-L
 *  taken from Ian's unix example
 *
 */

#include "sqMacCroquet.h"
#include "sqMemoryAccess.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h> 


sqInt ioGatherEntropy(char *buffer, sqInt bufSize)
{
  int fd, count= 0;

  if ((fd= open("/dev/urandom", O_RDONLY)) < 0)
    return 0;

  while (count < bufSize)
    {
      int n;
      if ((n= read(fd, buffer + count, bufSize)) < 1)
	break;
      count += n;
    }

  close(fd);

  return count == bufSize;
}
