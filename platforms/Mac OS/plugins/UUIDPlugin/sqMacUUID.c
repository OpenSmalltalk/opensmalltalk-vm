/****************************************************************************
*   PROJECT: UUID support for the mac
*   FILE:    sqMacUUID.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacUUID.c,v 1.3 2002/02/05 20:05:57 johnmci Exp $
*
*   Feb 5 2002, JMM cleanup for windows port
*
*/

#include "UUIDPlugin.h"
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;

#if TARGET_API_MAC_CARBON
#include <CFUUID.h>

int MakeUUID(sqUUID location) {
    CFUUIDRef theUUID;
    CFUUIDBytes theBytes;

    theUUID =  CFUUIDCreate (null);
    theBytes = CFUUIDGetUUIDBytes(theUUID);
    memcpy((char *) location,(char *) &theBytes,sizeof(sqUUID));
    CFRelease(theUUID);
}

int sqUUIDInit() {
    return 1;
}

int sqUUIDShutdown() {
    return 1;
}
#else
static Boolean gInit= false;
int sqUUIDInit() {
    return 0;
}

MakeUUID(sqUUID location) {
    interpreterProxy->success(false);
}

int sqUUIDShutdown() {
    return 0;
}
#endif


