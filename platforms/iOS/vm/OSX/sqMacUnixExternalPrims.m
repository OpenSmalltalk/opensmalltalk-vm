
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
#import "sqAssert.h"

extern SqueakOSXAppDelegate *gDelegateApp;
#define thePListInterface ((sqSqueakOSXInfoPlistInterface *)gDelegateApp.squeakApplication.infoPlistInterfaceLogic)

#define dprintf(ARGS) do { if (thePListInterface.SqueakDebug) fprintf ARGS; } while (0)

// In practice these reasons are too important to hide. So if VM compiled with
// -DPRINT_DL_ERRORS=1 always print dlopen errors
#if PRINT_DL_ERRORS
# define defprintf(ARGS) fprintf ARGS
#else
# define defprintf(ARGS) dprintf(ARGS)
#endif

#if defined(HAVE_LIBDL)	/* non-starter without this! */

#include <dlfcn.h> 
#include <sys/param.h>
#include <sys/stat.h>
#include <errno.h>

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
	const char *libName = [libNameString fileSystemRepresentation];

	if (stat(libName, &buf))
		dprintf((stderr, "%s does not exist\n", libName));
	else if (S_ISDIR(buf.st_mode))
		dprintf((stderr, "ignoring directory: %s\n", libName));
	else {
		const char *why;
		dprintf((stderr, "tryLoading %s\n", libName));
		if ((handle = dlopen(libName, RTLD_NOW | RTLD_GLOBAL)))
			return handle;
		why = dlerror();
#if PRINT_DL_ERRORS // In practice these reasons are too important to hide
		fprintf(stderr, "ioLoadModule(%s):\t%s\n", libName, why);
#else
		if (thePListInterface.SqueakDebug)
			fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, why);
		else if (strstr(why,"undefined symbol"))
			fprintf(stderr, "tryLoadingInternals: dlopen: %s\n", why);
#endif
	}
	return NULL;
}

/* Function to attempt to load a bundle for moduleName under dirNameString, e.g.
 * VM.app/Resources/<moduleName>.bundle/Contents/MacOS/<moduleName>
 */
static void *
tryLoadingBundle(NSString *dirNameString, char *moduleName)
{
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
	const char  *dirName;
	char	   **prefix, **suffix;
	struct stat  buf;
	static char *prefixes[]= { "", "lib", 0 };
#if PharoVM
	static char *suffixes[]= { "", "so", "dylib", 0 };
#else
	static char *suffixes[]= { "", "dylib", "so", 0 };
#endif

	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly)
		return NULL;

	/* don't prepend dirNameString to absolute paths */
	if (*moduleName == '/')
		return NULL;

	dirName = [dirNameString length] == 0
				? 0
				: [dirNameString fileSystemRepresentation];
	/* If dirName does not exist it is pointless searching for libraries in it. */
	if (dirName && stat(dirName,&buf)) {
		if (errno != ENOENT)
			fprintf(stderr,
					"tryLoading(%s,%s): stat(%s) %s\n",
					dirName, moduleName, dirName, strerror(errno));
		else if (thePListInterface.SqueakDebug)
			fprintf(stderr,"skipping non-existent directory %s\n", dirName);
		return NULL;
	}
	for (prefix= prefixes;  *prefix;  ++prefix)
		for (suffix= suffixes;  *suffix;  ++suffix)	{
			libName = [dirNameString stringByAppendingPathComponent: @(*prefix)];
			libName = **prefix
					? [libName stringByAppendingString: @(moduleName)]
					: [libName stringByAppendingPathComponent: @(moduleName)];
			if (**suffix)
				libName = [libName stringByAppendingPathExtension: @(*suffix)];

			if ((handle = tryLoadingInternals(libName)))
				return handle;
		}
	return NULL;
}

static void *
tryLoadingLinked(char *libName)
{
	struct stat buf;
	void        *handle;

#if !PharoVM
	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly)
		return NULL;
#endif

#if 0 // This seems like the right thing to do but it breaks ioLoadModule
	  // ioLoadModule for system dylibs found along the system path(2).
	  // Instead, filter-out noise errors below
	if (stat(libName, &buf)) {
		dprintf((stderr, "tryLoadingLinked(%s) does not exist\n", libName));
		return 0;
	}
	else if (S_ISDIR(buf.st_mode)) {
		dprintf((stderr, "tryLoadingLinked(%s) is a directory\n", libName));
		return 0;
	}
#endif

	handle = dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
#if DEBUG
	if (handle)
		printf("%s: loaded plugin `%s'\n", exeName, libName);
#endif
	if (!handle) {
		const char *why = dlerror();
		// filter out failures due to non-existent libraries
		if (stat(libName, &buf)) {
			defprintf((stderr, "tryLoadingLinked(%s) does not exist\n", libName));
			return 0;
		}
		else if (S_ISDIR(buf.st_mode)) {
			defprintf((stderr, "tryLoadingLinked(%s) is a directory\n", libName));
			return 0;
		}
#if PRINT_DL_ERRORS // In practice these reasons are too important to hide
		fprintf(stderr, "tryLoadingLinked(%s):\t%s\n", libName, why);
#else
		if (thePListInterface.SqueakDebug)
			fprintf(stderr, "tryLoadingLinked(%s):\n  %s\n", libName, why);
		else if (strstr(why,"undefined symbol"))
			fprintf(stderr, "tryLoadingLinked: dlopen: %s\n", why);
#endif
	}
	return handle;
}

/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *
ioLoadModule(char *pluginName) {
	@autoreleasepool {
		return ioLoadModuleRaw(pluginName);
	}
}

void *
ioLoadModuleRaw(char *pluginName)
{
	void *handle;

	if (!pluginName || !pluginName[0]) {
		handle = dlopen(0, RTLD_NOW | RTLD_GLOBAL);
		if (!handle) {
			char * why = dlerror();
			defprintf((stderr, "ioLoadModule(<intrinsic>): %s\n", why));
			return NULL;
		}
		dprintf((stderr, "loaded: <intrinsic>\n"));
		return handle;
	}

#if PharoVM
	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
	NSString *pluginDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/MacOS/Plugins"];
#endif
	NSString *frameworksDirPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/Frameworks"];
	NSString *vmDirPath = [[NSBundle mainBundle] resourcePath];

	if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
	  if ((   handle= tryLoadingLinked(                     pluginName))
		  || (handle= tryLoadingBundle( vmDirPath,			pluginName))
		  || (handle= tryLoadingVariations( frameworksDirPath,	pluginName))
#if PharoVM
		  || (handle= tryLoadingVariations( pluginDirPath,	pluginName))
#endif
		  )
		return handle;
	}
	else {
	  if ((   handle= tryLoadingLinked(                     pluginName))
		  || (handle= tryLoadingBundle( vmDirPath,			pluginName))
		  || (handle= tryLoadingVariations( frameworksDirPath,	pluginName))
#if PharoVM
		  || (handle= tryLoadingVariations( pluginDirPath,	pluginName))
#endif
		  || (handle= tryLoadingVariations( @"./",			pluginName))
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
			RETAINVALUE(myURLRef.path);
			systemFolder = myURLRef.path;
		}

#define LENGTHOFDOTFRAMEWORK 10 /* i.e. strlen(".framework") */
#define LODF LENGTHOFDOTFRAMEWORK /* and same for short */
		pluginNameLength = strlen(pluginName);
		if (pluginNameLength > LENGTHOFDOTFRAMEWORK) {
			strncpy(workingData,pluginName+pluginNameLength-LODF,LODF);
			workingData[LODF] = 0x00;
			if (!strcmp(workingData,".framework")) {
				strncpy(workingData,pluginName,pluginNameLength-LODF);
				workingData[pluginNameLength-LODF] = 0x00;
				path = [vmDirPath stringByAppendingPathComponent: @(pluginName)];
				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				}
				else if ((handle= tryLoadingVariations(path, workingData)))
					return handle;

#if PharoVM
				path = [pluginDirPath stringByAppendingPathComponent: @(pluginName)];

				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				}
				else if ((handle= tryLoadingVariations(path, workingData)))
					return handle;
#endif

				path = [systemFolder stringByAppendingPathComponent: @(pluginName)];
				if (thePListInterface.SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				}
				else if ((handle= tryLoadingVariations(path, workingData)))
					return handle;
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
ioFindExternalFunctionInMetadataInto(char *lookupName, void *moduleHandle,
											sqInt *metadataPtr)
#else
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
#endif
{
  void *fn = dlsym(moduleHandle, lookupName);

  dprintf((stderr, "ioFindExternalFunctionIn(%s, %p)\n",lookupName, moduleHandle));

  if (!fn
	&& thePListInterface.SqueakDebug
	&& strcmp(lookupName, "initialiseModule")
	&& strcmp(lookupName, "shutdownModule")
	&& strcmp(lookupName, "setInterpreter")
	&& strcmp(lookupName, "getModuleName"))
	fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",
			lookupName, moduleHandle, dlerror());

#if SPURVM
  if (fn && metadataPtr) {
	char buf[NAME_MAX+1];
	SpurPrimitiveMetadataType *metadataVarPtr;

	snprintf(buf, sizeof(buf), "%sMetadata", lookupName); 
	metadataVarPtr = dlsym(moduleHandle, buf);
	/* The Slang machinery assumes accessor depth defaults to -1, which
	 * means "no accessor depth".  It saves space not outputting null metadata.
	 */
	*metadataPtr = metadataVarPtr
							? *metadataVarPtr
							: NullSpurMetadata;
	assert(validSpurPrimitiveMetadata(*metadataPtr));
  }
#endif /* SPURVM */

  return fn;
}

/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt
ioFreeModule(void *moduleHandle)
{
	if (!dlclose(moduleHandle))
		return 1;

	char *why = dlerror();
	defprintf((stderr, "ioFreeModule(%ld): %s\n", (long) moduleHandle, why));
	return 0;
}
