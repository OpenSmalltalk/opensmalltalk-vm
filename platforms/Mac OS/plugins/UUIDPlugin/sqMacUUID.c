#include "UUIDPlugin.h"

#include "sq.h"

extern struct VirtualMachine *interpreterProxy;
static Boolean gInit= false;

int sqUUIDInit() {
    SetUpUUID(UUID_Version_1_DCE,UUID_Variant_GUID,0,0);
    return 1;
}