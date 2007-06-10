#include <unistd.h>
#include <sys/mman.h>
#include "ExuperyPlugin.h"
#include <stdio.h>
#include <stdlib.h>

int ioMapCodeCache(int size) {
  void *value;
  long	error;
	extern int errno;
  value = (void*) mmap(0, size,
		    PROT_READ|PROT_WRITE|PROT_EXEC,
		     MAP_ANON|MAP_SHARED,-1,0);
  if ((int) value == -1) {
		error = errno;
		fprintf(stderr,"ioMapCodeCache failed %i\n",error);
		exit(-1);
	}
}
