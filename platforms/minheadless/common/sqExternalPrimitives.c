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

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#include <stdio.h>
#include "sq.h"

int sqVMOptionTraceModuleLoading = 0;

static void *loadModuleHandle(const char *fileName);
static sqInt freeModuleHandle(void *module);
static void *getModuleSymbol(void *module, const char *symbol);

/* Modules */
extern char *squeakPlugins;
extern char squeakExtraPluginsPath[];

static const char *moduleNamePatterns[] = {
    "%s%s",
#if defined(_WIN32)
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

static const char *additionalModuleSearchPaths[] = {
#ifdef _WIN32
#endif
#if defined(__linux__) || defined(unix) || defined(__APPLE__)
    "/usr/local/lib/",
    "/usr/lib/",
    "/lib/",
#   if defined(__linux__)
#       if defined(__i386__)
    "/usr/local/lib/i386-linux-gnu/",
    "/usr/lib/i386-linux-gnu/",
    "/lib/i386-linux-gnu/",
#       elif defined(__x86_64__)
    "/usr/local/lib/x86_64-linux-gnu/",
    "/usr/lib/x86_64-linux-gnu/",
    "/lib/x86_64-linux-gnu/",
#       endif
#   endif
#endif
    NULL
};

static char moduleNameBuffer[FILENAME_MAX];

static void *
tryToLoadModuleInPath(const char *path, const char *moduleName)
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

void *
ioLoadModule(char *pluginName)
{
    void *moduleHandle;

    moduleHandle = tryToLoadModuleInPath(squeakPlugins, pluginName);
    if(moduleHandle)
        return moduleHandle;

    moduleHandle = tryToLoadModuleInPath(squeakExtraPluginsPath, pluginName);
    if(moduleHandle)
        return moduleHandle;

    moduleHandle = tryToLoadModuleInPath("", pluginName);
    if(moduleHandle)
        return moduleHandle;

    const char **currentPath = additionalModuleSearchPaths;
    for(; *currentPath; ++currentPath)
    {
        moduleHandle = tryToLoadModuleInPath(*currentPath, pluginName);
        if(moduleHandle)
            return moduleHandle;
    }

    if(sqVMOptionTraceModuleLoading)
        fprintf(stderr, "Failed to load module: %s\n", pluginName);
    return 0;
}

sqInt
ioFreeModule(void *moduleHandle)
{
    return freeModuleHandle(moduleHandle);
}

#if SPURVM
void *
ioFindExternalFunctionInMetadataInto(char *lookupName, void *moduleHandle,
											sqInt *metadataPtr)
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
    if (function && metadataPtr)
    {
        char buf[256];
        signed short *metadataVarPtr;

        strcpy(buf, lookupName);
    	snprintf(buf+strlen(buf), sizeof(buf) - strlen(buf), "Metadata");
    	metadataVarPtr = getModuleSymbol(moduleHandle, buf);
    	/* The Slang machinery assumes accessor depth defaults to -1, which
    	 * means "no accessor depth".  It saves space not outputting -1 depths.
    	 */
    	*metadataPtr = metadataVarPtr
    							? *metadataVarPtr
    							: -1;
    }
#endif /* SPURVM */
    return function;
}

#if defined(_WIN32)

static void *
loadModuleHandle(const char *fileName)
{
    WCHAR convertedPath[MAX_PATH + 1];
    sqUTF8ToUTF16Copy(convertedPath, MAX_PATH + 1, fileName);
#ifdef DEBUG
    printf("try loading  %s\n", fileName);
#endif
    return LoadLibraryW(convertedPath);
}

static sqInt
freeModuleHandle(void *module)
{
    return FreeLibrary((HMODULE)module) ? 1 : 0;
}

static void *
getModuleSymbol(void *module, const char *symbol)
{
    return (void*)GetProcAddress((HMODULE)module, symbol);
}

#elif defined(__linux__) || defined(__unix__) || defined(__APPLE__)

#include <dlfcn.h>

static void *
loadModuleHandle(const char *fileName)
{
    int flags = RTLD_NOW | RTLD_GLOBAL;
#ifdef RTLD_DEEPBIND
    flags |= RTLD_DEEPBIND; /* Prefer local symbols in the shared object vs external symbols. */
#endif

#ifdef DEBUG
    printf("try loading  %s\n", fileName);
#endif
    return dlopen(fileName, flags);
}

static sqInt
freeModuleHandle(void *module)
{
    return dlclose(module) == 0 ? 0 : 1;
}

static void *
getModuleSymbol(void *module, const char *symbol)
{
    return dlsym(module, symbol);
}

#else

static void *
loadModuleHandle(const char *fileName)
{
    return 0;
}

static sqInt
freeModuleHandle(void *module)
{
    return 1;
}

static void *
getModuleSymbol(void *module, const char *symbol)
{
    return 0;
}

#endif
