#include <uuid/uuid.h>
#include "sq.h"

int sqUUIDInit(void)
{
  return 1;
}

int sqUUIDShutdown(void)
{
  return 1;
}

int MakeUUID(char *location)
{
  uuid_t uuid;
  uuid_generate(uuid);
  memcpy((void *)location, (void *)&uuid, sizeof(uuid));
  return 1;
}
