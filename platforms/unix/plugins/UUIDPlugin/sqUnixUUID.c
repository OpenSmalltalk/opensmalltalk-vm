#include "config.h"

#if defined(HAVE_SYS_UUID_H)
# include <sys/types.h>
# include <sys/uuid.h>
#elif defined(HAVE_UUID_UUID_H)
# include <uuid/uuid.h>
#elif defined(HAVE_UUID_H)
# include <uuid.h>
#else
# error cannot find a uuid.h to include
#endif

#include "sq.h"


int MakeUUID(char *location)
{
  uuid_t uuid;

#if defined(HAVE_UUIDGEN)
  uuidgen(&uuid, 1);
#elif defined(HAVE_UUID_GENERATE)
  uuid_generate(uuid);
#else
# error "you must define some way of generating a UUID."
#endif

  memcpy((void *)location, (void *)&uuid, sizeof(uuid));
  return 1;
}


#if defined(__linux__)

# include <setjmp.h>
# include <signal.h>

static sigjmp_buf env;

static void sigsegvHandler(int signal)
{
  siglongjmp(env, 1);
}

int sqUUIDInit(void)
{
  /* check if we get a segmentation fault when using libuuid */
  int pluginAvailable= 0;
  struct sigaction originalAction;
  uuid_t uuid;

  if (!sigsetjmp(env, 1))
    {
      struct sigaction newAction;
      newAction.sa_handler= sigsegvHandler;
      newAction.sa_flags= 0;
      sigemptyset(&newAction.sa_mask);
	  
      if (sigaction(SIGSEGV, &newAction, &originalAction))
	/* couldn't change the signal handler: give up now */
	return 0;
      else
	pluginAvailable= MakeUUID((char *)&uuid);
    }

  sigaction(SIGSEGV, &originalAction, NULL);

  return pluginAvailable;
}

#else /* !__linux__ */

int sqUUIDInit(void)
{
  return 1;
}

#endif /* !__linux__ */


int sqUUIDShutdown(void)
{
  return 1;
}
