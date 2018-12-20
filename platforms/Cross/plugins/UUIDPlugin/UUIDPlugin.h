/* UUID generation. Note that we typedef sqUUID as a generic 128 bit value so that platform specific code can coerce appropriately. */

typedef char sqUUID[16];

int MakeUUID(sqUUID location);
int sqUUIDInit(void);
int sqUUIDShutdown(void);
