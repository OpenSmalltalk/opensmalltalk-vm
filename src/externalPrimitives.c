/* sqExternalPrimitives.c -- Support functions for loading external primitives.
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */

#ifdef WIN64
#include <windows.h>
#endif

#include "pharovm/pharo.h"

int sqVMOptionTraceModuleLoading = 0;

void *loadModuleHandle(const char *fileName);
sqInt freeModuleHandle(void *module);
void *getModuleSymbol(void *module, const char *symbol);

const char *moduleNamePatterns[] = {
    "%s%s",
#if defined(WIN64)
    "%s%s.dll",
    "%slib%s.dll",
#elif defined(__APPLE__)
    "%s%s",
    "%s%s.dylib",
    "%slib%s.dylib",
#else
    "%s%s.so",
    "%slib%s.so",
#endif
    NULL
};

char moduleNameBuffer[FILENAME_MAX];

void * tryToLoadModuleInPath(char *path, const char *moduleName)
{
    void *moduleHandle;
    int i = 0;

    for(int i=0; moduleNamePatterns[i] != NULL; i++)
    {
        snprintf(moduleNameBuffer, FILENAME_MAX, moduleNamePatterns[i], path, moduleName);
        moduleNameBuffer[FILENAME_MAX - 1] = 0;
        moduleHandle = loadModuleHandle(moduleNameBuffer);
        if(moduleHandle){
        	return moduleHandle;
        }
    }

    return 0;
}

void *
ioLoadModule(char *pluginName)
{
    void *moduleHandle;
    char** paths = getPluginPaths();

    for(int i=0; paths[i] != NULL; i++){
    	moduleHandle = tryToLoadModuleInPath(paths[i], pluginName);
    	if(moduleHandle)
    		return moduleHandle;
    }

    moduleHandle = tryToLoadModuleInPath("", pluginName);
    if(moduleHandle)
        return moduleHandle;

    char **currentPath = getSystemSearchPaths();
    for(; *currentPath; ++currentPath)
    {
        moduleHandle = tryToLoadModuleInPath(*currentPath, pluginName);
        if(moduleHandle)
            return moduleHandle;
    }

    logWarn("Failed to load module: %s\n", pluginName);

    return 0;
}

sqInt
ioFreeModule(void *moduleHandle)
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

        strcpy(buf, lookupName);
    	snprintf(buf+strlen(buf), sizeof(buf) - strlen(buf), "AccessorDepth");
    	accessorDepthVarPtr = getModuleSymbol(moduleHandle, buf);
    	/* The Slang machinery assumes accessor depth defaults to -1, which
    	 * means "no accessor depth".  It saves space not outputting -1 depths.
    	 */
    	*accessorDepthPtr = accessorDepthVarPtr
    							? *accessorDepthVarPtr
    							: -1;

    	//If the primitive does not have accessor depth we generate a warning.
    	if(accessorDepthVarPtr == NULL)
    		logWarn("Missing Accessor Depth: %s", lookupName);
    }
#endif /* SPURVM */
    return function;
}

#if defined(WIN64)

void *
loadModuleHandle(const char *fileName)
{
    WCHAR convertedPath[MAX_PATH + 1];
    CHAR copiedFileName[MAX_PATH + 1];
    int len;

    len = strlen(fileName);
    memcpy(copiedFileName, fileName, len);
    copiedFileName[len] = 0;

    MultiByteToWideChar(CP_UTF8, 0, copiedFileName, -1, convertedPath, MAX_PATH + 1);

    logDebug("Try loading  %s\n", copiedFileName);

    HMODULE m = LoadLibraryW(convertedPath);

   	return m;
}

sqInt
freeModuleHandle(void *module)
{
    return FreeLibrary((HMODULE)module) ? 1 : 0;
}

void *
getModuleSymbol(void *module, const char *symbol)
{
    return (void*)GetProcAddress((HMODULE)(module ? module : GetModuleHandle(NULL)), symbol);
}

#elif defined(__linux__) || defined(__unix__) || defined(__APPLE__)

#include <dlfcn.h>

void *
loadModuleHandle(const char *fileName)
{
    int flags = RTLD_NOW | RTLD_GLOBAL;
#ifdef RTLD_DEEPBIND
    flags |= RTLD_DEEPBIND; /* Prefer local symbols in the shared object vs external symbols. */
#endif

    logTrace("Try loading  %s\n", fileName);
    return dlopen(fileName, flags);
}

sqInt
freeModuleHandle(void *module){
    return dlclose(module) == 0 ? 0 : 1;
}

void *
getModuleSymbol(void *module, const char *symbol)
{
    return dlsym(module ? module: dlopen(NULL,0), symbol);
}

#else

void *
loadModuleHandle(const char *fileName)
{
    return 0;
}

sqInt
freeModuleHandle(void *module)
{
	return 1;
}

static void *
getModuleSymbol(void *module, const char *symbol)
{
    return 0;
}

void *
getModuleSymbol(void *module, const char *symbol)
{
    return dlsym(module, symbol);
}

#endif
