#include <uuid/uuid.h>
#include "sq.h"

int sqUUIDInit(void) { return 1; }

int sqUUIDShutdown(void) { return 1; }

int MakeUUID(char *location)
{
  uuid_t uuid;
#if defined(__NetBSD__)
  uuidgen(&uuid, 1);
#else
  uuid_generate(uuid);
#endif
  memcpy((void *)location, (void *)&uuid, sizeof(uuid));
  return 1;
}
