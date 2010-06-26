#include "sqVirtualMachine.h"
extern struct VirtualMachine * interpreterProxy;
void sqFilenameFromStringOpen(char *buffer,long fileIndex, long fileLength, int flag) {
    interpreterProxy->ioFilenamefromStringofLengthresolveAliases(buffer,fileIndex, fileLength, flag);
}
