#include "UUIDPlugin.h"
#include "sq.h"

extern struct VirtualMachine *interpreterProxy;

#if TARGET_API_MAC_CARBON

int MakeUUID(UUIDD * location) {
    CFUUIDRef theUUID;
    CFUUIDBytes theBytes;

    theUUID =  CFUUIDCreate (null);
    theBytes = CFUUIDGetUUIDBytes(theUUID);
    memcpy((char *) location,(char *) &theBytes,sizeof(UUIDD));
    CFRelease(theUUID);
}

int sqUUIDInit() {
    return 1;
}

#else
static Boolean gInit= false;
int sqUUIDInit() {
    return 0;
}

MakeUUID(UUIDD * location) {
    interpreterProxy->success(false);
}
#endif


