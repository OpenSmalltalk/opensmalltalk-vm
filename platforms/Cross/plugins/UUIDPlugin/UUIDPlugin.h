/* UUID generation. Note that we typedef sqUUID as a generic 128 bit value so that platform specific code can coerce appropriately. */

typedef char sqUUID[16];

sqInt MakeUUID(sqUUID location);
sqInt sqUUIDInit(void);
sqInt sqUUIDShutdown(void);
