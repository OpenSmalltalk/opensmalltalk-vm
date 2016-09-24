
//  Created by John M McIntosh on 09-11-27.
//  This file orginally comes from the sqUnixExternalPrims.c written by Ian Piumarta
//  With additional work for the 3.x and 4.x series of macintosh carbon vms
//  To preserve the behavior, bugs, etc I decided to copy the code versus a new re-write

/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
 * 
 *   Copyright (C) 1996-2009 by Ian Piumarta
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

 /* Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2005-04-06 06:09:36 by piumarta on pauillac.hpl.hp.com

 * Altered by John M McIntosh johnmci@smalltalkconsulting.com Feb 24th, 2006 for os-x carbon support
 3.8.11b2 load from resource location first, avoid plugins external directory because of intel migration effort issues.
 3.8.17b1 April 25, 2007, JMM rework for 10.2.8 backwards support using Ian's dl* logic. 
 5.0.0b6  Nov 27, 2009, JMM rework for the 32/64bit 5.0 VM

 */
#import "sqSqueakOSXInfoPlistInterface.h"
#import "SqueakOSXAppDelegate.h"
#import "sq.h"

extern SqueakOSXAppDelegate *gDelegateApp;
#define thePListInterface ((sqSqueakOSXInfoPlistInterface *)gDelegateApp.squeakApplication.infoPlistInterfaceLogic)

#define dprintf(ARGS) do { if (thePListInterface.SqueakDebug) fprintf ARGS; } while (0)

#if defined(HAVE_LIBDL)	/* non-starter without this! */

#include <dlfcn.h> 
#include <sys/param.h>
#include <sys/stat.h>

/* get a value for RTLD_NOW, with increasing levels of desperation... */

#if !defined(RTLD_NOW)
# if defined(DL_NOW)
#   define RTLD_NOW DL_NOW
# elif defined(RTLD_LAZY)
#   define RTLD_NOW RTLD_LAZY
# elif defined(DL_LAZY)
#   define RTLD_NOW DL_LAZY
# else
#   warning: defining RTLD_NOW as 1
#   define RTLD_NOW 1
# endif
#endif

#if !defined(RTLD_GLOBAL)
# define RTLD_GLOBAL 0
#endif

#endif


/*** local functions ***/
void *ioLoadModuleRaw(char *pluginName);

/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded.
 */
static void *
tryLoadingInternals(NSString *libNameString)
{	
	struct stat buf;
	void        *handle;
	const char* libName = [libNameString fileSystemRepresentation];

	if (stat(libName, &buf))
		dprintf((stderr, "%s does not exist\n", libName));
	else if (S_ISDIR(buf.st_mode))
		dprintf((stderr, "ignoring directory: %s\n", libName));
	else {
	    dprintf((stderr, "tryLoading %s\n", libName));
		if ((handle = dlopen(libName, RTLD_NOW | RTLD_GLOBAL)))
			return handle;
		if (thePListInterface.SqueakDebug) {
			const char* why = dlerror();
			fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, why);
		}
	}
	return NULL;
}

/* Function to attempt to load a bundle for moduleName under dirNameString, e.g.
 * VM.app/Resources/<moduleName>.bundle/Contents/MacOS/<moduleName>
 */
static void *
tryLoadingBundle(NSString *dirNameString, char *moduleName)
{
	void        *handle;
	NSString    *libName;

	libName = [dirNameString stringByAppendingPathComponent: @(moduleName)];
	libName = [libName stringByAppendingPathExtension: @"bundle"];
	libName = [libName stringByAppendingPathComponent: @"Contents"];
	libName = [libName stringByAppendingPathComponent: @"MacOS"];
	libName = [libName stringByAppendingPathComponent: @(moduleName)];

	return tryLoadingInternals(libName);
}

/* Function to attempt to load a dylib for moduleName under dirNameString, e.g.
 * VM.app/Contents/MacOS/Plugins/<moduleName>
 * VM.app/Contents/MacOS/Plugins/lib<moduleName>
 * VM.app/Contents/MacOS/Plugins/<moduleName>.so
 * etc
 */
static void *
tryLoadingVariations(NSString *dirNameString, char *moduleName)
{
	void        *handle;
	NSString    *libName;
	char	     **prefix, **suffix;
	static char *prefixes[]= { "", "lib", 0 };
	static char *suffixes[]= { "", "so", "dylib",0 };

	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly)
		return NULL;

	/* don't prepend dirNameString to absolute paths */
	if (*moduleName == '/')
		return NULL;

	for (prefix= prefixes;  *prefix;  ++prefix)
		for (suffix= suffixes;  *suffix;  ++suffix)		{
			libName = [dirNameString stringByAppendingPathComponent: @(*prefix)];
			if (**prefix)
				libName = [libName stringByAppendingString: @(moduleName)];
			else
				libName = [libName stringByAppendingPathComponent: @(moduleName)];
			if (**suffix)
				libName = [libName stringByAppendingPathExtension: @(*suffix)];

			if ((handle = tryLoadingInternals(libName)))
				return handle;
		}
	return NULL;
}

#if PharoVM
static void *
tryLoadingLinked(char *libName)
{
    void *handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
    DPRINTF((stderr, __FILE__ " %d tryLoadingLinked dlopen(%s) = %p\n", __LINE__, libName, handle));
# if DEBUG
    if(handle != 0)
        printf("%s: loaded plugin `%s'\n", exeName, libName);
# endif
    return handle;
}
#else /* PharoVM */
static void *
tryLoadingLinked(char *libName)
{
    void *handle;

	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly)
		return NULL;

	handle = dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
    DPRINTF((stderr, __FILE__ " %d tryLoadingLinked dlopen(%s) = %p\n", __LINE__, libName, handle));
# if DEBUG
    if(handle != 0)
        printf("%s: loaded plugin `%s'\n", exeName, libName);
# endif
    return handle;
}
#endif /* PharoVM */

/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *
ioLoadModule(char *pluginName) {
	@autoreleasepool {
		void* result = ioLoadModuleRaw(pluginName);
		return result;
	}
}

void *
ioLoadModuleRaw(char *pluginName)
{
	void *handle;

	if ((pluginName == null) || (pluginName[0] == 0x00)) {
		handle = dlopen(0, RTLD_NOW | RTLD_GLOBAL);
		if (handle == null) {
			char * why = dlerror();
			dprintf((stderr, "ioLoadModule(<intrinsic>): %s\n", why));
			return NULL;
		} else {
			dprintf((stderr, "loaded: <intrinsic>\n"));
			return handle;
		}
    }

	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
	NSString *pluginDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/MacOS/Plugins"];
	NSString *vmDirPath = [[NSBundle mainBundle] resourcePath];

	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
	  if ((   handle= tryLoadingLinked(                     pluginName))
          || (handle= tryLoadingVariations( pluginDirPath,	pluginName))
		  || (handle= tryLoadingBundle( vmDirPath,			pluginName))
		  )
		return handle;
	}
    else {
	  if ((   handle= tryLoadingLinked(                     pluginName))
          || (handle= tryLoadingVariations( pluginDirPath,	pluginName))
		  || (handle= tryLoadingVariations( @"./",			pluginName))
		  || (handle= tryLoadingBundle( vmDirPath,			pluginName))
		  || (handle= tryLoadingVariations( @"",			pluginName))
		  )
		return handle;
	}

	// the following is needed so that, for example, the FFI can pick up
	// things like <cdecl: 'xyz' module: 'CoreServices'>
	{
		static char *frameworks[]=
		{
			"",
			"/CoreServices.framework/Frameworks",
			"/ApplicationServices.framework/Frameworks",
			"/Carbon.framework/Frameworks",
			0
		};

		static NSString *systemFolder = NULL;
		char **framework= NULL;
		char workingData[PATH_MAX+1];
		size_t pluginNameLength;
		NSString *path,*path2;

		if (!systemFolder) {
			struct FSRef frameworksFolderRef;
			OSErr err = FSFindFolder(kSystemDomain, kFrameworksFolderType, false, &frameworksFolderRef);
#pragma unused(err)
			NSURL *myURLRef = (NSURL *) CFBridgingRelease(CFURLCreateFromFSRef(kCFAllocatorDefault, &frameworksFolderRef));
			RETAINOBJ(myURLRef.path);
			systemFolder = myURLRef.path;
		}

#define LENGTHOFDOTFRAMEWORK 10 /* i.e. strlen(".framework") */
#define LODF LENGTHOFDOTFRAMEWORK /* and same for short */
		pluginNameLength = strlen(pluginName);
		if (pluginNameLength > LENGTHOFDOTFRAMEWORK) {
			strncpy(workingData,pluginName+pluginNameLength-LODF,LODF);
			workingData[LODF] = 0x00;
			if (strcmp(workingData,".framework") == 0) {
				strncpy(workingData,pluginName,pluginNameLength-LODF);
				workingData[pluginNameLength-LODF] = 0x00;
				path = [vmDirPath stringByAppendingPathComponent: @(pluginName)];
				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoadingVariations(path, workingData)))
						return handle;
				}
				path = [pluginDirPath stringByAppendingPathComponent: @(pluginName)];

				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoadingVariations(path, workingData)))
						return handle;
				}

				path = [systemFolder stringByAppendingPathComponent: @(pluginName)];
				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoadingVariations(path, workingData)))
						return handle;
				}
			}
		}

		if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly)
			return NULL;

		for (framework= frameworks;  *framework;  ++framework) {
			path = [[systemFolder stringByAppendingPathComponent: @(*framework)]
					stringByAppendingPathComponent: @(pluginName)];
			if ((handle= tryLoadingVariations(path, pluginName)))
				return handle;

			path = [systemFolder stringByAppendingPathComponent: @(*framework)];
			path = [path stringByAppendingPathComponent: @(pluginName)];
			path = [path stringByAppendingPathExtension: @"framework"];

			if ((handle= tryLoadingVariations(path, pluginName)))
				return handle;
		}
	}

	return NULL;
}


/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
#if SPURVM
void *
ioFindExternalFunctionInAccessorDepthInto(char *lookupName, void *moduleHandle,
											sqInt *accessorDepthPtr)
#else
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
#endif
{
  char buf[NAME_MAX+1];

  snprintf(buf, sizeof(buf), "%s", lookupName); 
  void *fn = dlsym(moduleHandle, buf);

  dprintf((stderr, "ioFindExternalFunctionIn(%s, %ld)\n",lookupName, (long) moduleHandle));

  if ((fn == NULL) && (thePListInterface.SqueakDebug)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName")) {
	char *why = dlerror();
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",lookupName, moduleHandle, why);
	}

#if SPURVM
  if (fn && accessorDepthPtr) {
	signed char *accessorDepthVarPtr;
	snprintf(buf+strlen(buf), sizeof(buf), "AccessorDepth");
	accessorDepthVarPtr = dlsym(moduleHandle, buf);
	/* The Slang machinery assumes accessor depth defaults to -1, which
	 * means "no accessor depth".  It saves space not outputting -1 depths.
	 */
	*accessorDepthPtr = accessorDepthVarPtr
							? *accessorDepthVarPtr
							: -1;
  }
#endif /* SPURVM */

  return fn;
}

/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt ioFreeModule(void *moduleHandle)
{
  int results = dlclose(moduleHandle);

  if (results) {
	  char* why = dlerror();
      dprintf((stderr, "ioFreeModule(%ld): %s\n", (long) moduleHandle, why));
      return 0;
    }
  return 1;
}
