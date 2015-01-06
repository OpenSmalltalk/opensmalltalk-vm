/*
 *  macFileNameBits.c
 *  FT2Plugin support
 *
 *  Created by John M McIntosh on 21/11/05.
 * Feb 15th, 2006, use sqFilenameFromString
 *
 */
#include "sqVirtualMachine.h" 

extern struct VirtualMachine * interpreterProxy;

void		sqFilenameFromStringOpen(char *buffer,long fileIndex, long fileLength, int flag) {
	interpreterProxy->ioFilenamefromStringofLengthresolveAliases(buffer,fileIndex, fileLength, flag);
}
