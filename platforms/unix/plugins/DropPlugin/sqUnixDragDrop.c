#include "sq.h"
#include "sqVirtualMachine.h"
#include "FilePlugin.h"
#include "DropPlugin.h"


extern struct VirtualMachine *interpreterProxy;


int dropInit(void)
{
  return 0;  /* fail */
}


int dropShutdown()
{
  return 1;
}


char *dropRequestFileName(int dropIndex)
{
  return NULL;
}


int dropRequestFileHandle(int dropIndex)
{
  return interpreterProxy->nilObject();
}


int sqSecFileAccessCallback(void *callback)
{
  return 0;
}

void sqSetNumberOfDropFiles(int numberOfFiles)
{
}

void sqSetFileInformation(int dropIndex, void *dropFile)
{
}
