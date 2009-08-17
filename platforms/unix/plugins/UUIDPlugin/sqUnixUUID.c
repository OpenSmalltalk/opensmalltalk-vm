#include "config.h"
#if defined(HAVE_UUID_H)
# include <uuid.h>
#elif defined(HAVE_UUID_UUID_H)
# include <uuid/uuid.h>
#endif
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
