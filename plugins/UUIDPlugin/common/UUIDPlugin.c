#include "config.h"
#include "sq.h"

typedef char sqUUID[16];

int MakeUUID(sqUUID location);
int sqUUIDInit(void);
int sqUUIDShutdown(void);

struct VirtualMachine* interpreterProxy;

#ifdef _WIN32
	#include <windows.h>
	#include <ole2.h>

	int
	MakeUUID(char *location) {
		if (CoCreateGuid((GUID*)location) == S_OK)
			return 1;
		interpreterProxy->primitiveFail();
		return 0;
	}


#else

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

	int MakeUUID(char *location)
	{
	  uuid_t uuid;

	#if defined(HAVE_UUIDGEN)
	  uuidgen(&uuid, 1);
	#else
	  uuid_generate(uuid);
	#endif

	  memcpy((void *)location, (void *)&uuid, sizeof(uuid));
	  return 1;
	}
#endif

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

EXPORT(sqInt) setInterpreter(struct VirtualMachine *anInterpreter)
{
    sqInt ok;

	interpreterProxy = anInterpreter;
	
	return 0;
}

EXPORT(const char*)
getModuleName(void)
{
	return "UUIDPlugin";
}

EXPORT(sqInt)
initialiseModule(void)
{
return sqUUIDInit();
}

EXPORT(sqInt)
shutdownModule(void)
{
	return sqUUIDShutdown();
}

/* UUIDPlugin>>#primitiveMakeUUID */
EXPORT(sqInt)
primitiveMakeUUID(void)
{
	char *location;
	sqInt oop;

	oop = interpreterProxy->stackValue(0);
	if (!(((interpreterProxy->methodArgumentCount()) == 0)
			&& ((interpreterProxy->isBytes(oop))
					&& ((interpreterProxy->byteSizeOf(oop)) == 16)))) {
		return interpreterProxy->primitiveFail();
	}
	location = interpreterProxy->firstIndexableField(oop);
	MakeUUID(location);
	return oop;
}

#ifdef SQUEAK_BUILTIN_PLUGIN

static char _m[] = "UUIDPlugin";
void* UUIDPlugin_exports[][3] = {
	{(void*)_m, "getModuleName", (void*)getModuleName},
	{(void*)_m, "initialiseModule", (void*)initialiseModule},
	{(void*)_m, "primitiveMakeUUID\000\001", (void*)primitiveMakeUUID},
	{(void*)_m, "setInterpreter", (void*)setInterpreter},
	{(void*)_m, "shutdownModule\000\377", (void*)shutdownModule},
	{NULL, NULL, NULL}
};

#else /* ifdef SQ_BUILTIN_PLUGIN */

EXPORT(signed char) primitiveMakeUUIDAccessorDepth = 1;

#endif /* ifdef SQ_BUILTIN_PLUGIN */
