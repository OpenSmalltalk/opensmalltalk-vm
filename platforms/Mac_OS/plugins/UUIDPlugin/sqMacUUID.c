/****************************************************************************
*   PROJECT: UUID support for the mac
*   FILE:    sqMacUUID.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUUID.c 1708 2007-06-10 00:40:04Z johnmci $
*
*   Feb 5 2002, JMM cleanup for windows port
*
*/

#include "UUIDPlugin.h"
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;

#if TARGET_API_MAC_CARBON
#include <Carbon/Carbon.h>
#else
#include <CFUUID.h>
#endif

int sqUUIDInit(void);
int sqUUIDShutdown(void);

int MakeUUID(sqUUID location) {
    CFUUIDRef theUUID;
    CFUUIDBytes theBytes;

    theUUID =  CFUUIDCreate (null);
    theBytes = CFUUIDGetUUIDBytes(theUUID);
    memcpy((char *) location,(char *) &theBytes,sizeof(sqUUID));
    CFRelease(theUUID);
	return 0;
}

int sqUUIDInit() {
    return 1;
}

int sqUUIDShutdown() {
    return 1;
}
