#include <stdio.h>
#include "sq.h"

static void *loadModuleHandle(const char *fileName);
static sqInt freeModuleHandle(void *module);
static void *getModuleSymbol(void *module, const char *symbol);

/* Modules */
extern char *squeakPlugins;

static const char *moduleNamePatterns[] = {
#ifdef _WIN32
    "%s%s.dll",
#elif __APPLE__
    "%s%s",
    "%s%s.dylib",
    "%slib%s.dylib",
#else
    "%s%s",
    "%s%s.so",
    "%slib%s.so",
#endif
    NULL
};

static const char *additionalModuleSearchPaths[] = {
    NULL
};

static char moduleNameBuffer[FILENAME_MAX];

static void *tryToLoadModuleInPath(const char *path, const char *moduleName)
{
    void *moduleHandle;

    const char **currentPattern = moduleNamePatterns;
    for(; *currentPattern; ++currentPattern)
    {
        snprintf(moduleNameBuffer, FILENAME_MAX, *currentPattern, path, moduleName);
        moduleNameBuffer[FILENAME_MAX - 1] = 0;
        moduleHandle = loadModuleHandle(moduleNameBuffer);
        if(moduleHandle)
            return moduleHandle;
    }

    return 0;
}

void *ioLoadModule(char *pluginName)
{
    void *moduleHandle;

    moduleHandle = tryToLoadModuleInPath(squeakPlugins, pluginName);
    if(moduleHandle)
        return moduleHandle;

    const char **currentPath = additionalModuleSearchPaths;
    for(; *currentPath; ++currentPath)
    {
        moduleHandle = tryToLoadModuleInPath(*currentPath, pluginName);
        if(moduleHandle)
            return moduleHandle;
    }

#if 1
    fprintf(stderr, "Failed to load module: %s\n", pluginName);
#endif
    return 0;
}

sqInt ioFreeModule(void *moduleHandle)
{
    return freeModuleHandle(moduleHandle);
}

#if SPURVM
void *
ioFindExternalFunctionInAccessorDepthInto(char *lookupName, void *moduleHandle,
											sqInt *accessorDepthPtr)
#else
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
#endif
{
    void *function;

    if (!*lookupName) /* avoid errors in dlsym from eitherPlugin: code. */
      return 0;

    function = getModuleSymbol(moduleHandle, lookupName);

#if SPURVM
    if (function && accessorDepthPtr)
    {
        char buf[256];
        signed char *accessorDepthVarPtr;

    	snprintf(buf+strlen(buf), sizeof(buf) - strlen(buf), "AccessorDepth");
    	accessorDepthVarPtr = getModuleSymbol(moduleHandle, buf);
    	/* The Slang machinery assumes accessor depth defaults to -1, which
    	 * means "no accessor depth".  It saves space not outputting -1 depths.
    	 */
    	*accessorDepthPtr = accessorDepthVarPtr
    							? *accessorDepthVarPtr
    							: -1;
    }
#endif /* SPURVM */
    return function;
}

#if defined(_WIN32)

#elif defined(__linux__) || defined(__unix__)

#include <dlfcn.h>

static void *loadModuleHandle(const char *fileName)
{
    int flags = RTLD_NOW | RTLD_GLOBAL;
#ifdef RTLD_DEEPBIND
    flags |= RTLD_DEEPBIND; /* Prefer local symbols in the shared object vs external symbols. */
#endif

    return dlopen(fileName, flags);
}

static sqInt freeModuleHandle(void *module)
{
    return dlclose(module) == 0 ? 0 : 1;
}

static void *getModuleSymbol(void *module, const char *symbol)
{
    return dlsym(module, symbol);
}

#else

static void *loadModuleHandle(const char *fileName)
{
    return 0;
}

static sqInt freeModuleHandle(void *module)
{
    return 1;
}

static void *getModuleSymbol(void *module, const char *symbol)
{
    return 0;
}

#endif
